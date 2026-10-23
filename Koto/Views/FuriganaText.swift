import SwiftUI

/// Message text with furigana over the kanji. Words wrap like normal text.
/// Tapping a Japanese word calls `onWordTap` with the text to look up; pressing and
/// dragging across words highlights them and calls `onSelect` with the highlighted text.
struct FuriganaText: View {
    @Environment(\.theme) private var theme
    let onWordTap: (String) -> Void
    var onSelect: ((String) -> Void)?

    private let tokens: [FuriganaToken]
    /// Indices into `tokens`, grouped into lines at each line break.
    private let lines: [[Int]]
    /// Tokens that make up the word passed as `highlighting`, drawn in the accent color.
    private let highlighted: Set<Int>
    /// Only reserve space above the text when something has a reading.
    private let hasReadings: Bool
    @AppStorage(AppSettings.furiganaKey) private var showFurigana = true
    /// Deck words known well enough that their readings are hidden.
    @Environment(\.knownWords) private var knownWords

    /// Where each token is drawn, for finding the word under the finger.
    @State private var frames: [Int: CGRect] = [:]
    /// Where the highlight started, and the highlighted token range.
    @State private var anchor: Int?
    @State private var selection: ClosedRange<Int>?

    private var showsReadings: Bool { hasReadings && showFurigana }

    /// - Parameter word: a dictionary form to emphasize wherever it appears, e.g. a flashcard's word
    ///   in its example sentence.
    init(
        _ text: String,
        highlighting word: String? = nil,
        onWordTap: @escaping (String) -> Void,
        onSelect: ((String) -> Void)? = nil
    ) {
        self.onWordTap = onWordTap
        self.onSelect = onSelect
        let tokens = Furigana.tokens(for: text)
        var lines: [[Int]] = [[]]
        for (index, token) in tokens.enumerated() {
            if token.isLineBreak {
                lines.append([])
            } else {
                lines[lines.count - 1].append(index)
            }
        }
        self.tokens = tokens
        self.lines = lines

        var highlighted: Set<Int> = []
        if let word, let range = Furigana.occurrence(of: word, in: text) {
            let start = range.lowerBound.utf16Offset(in: text)
            let end = range.upperBound.utf16Offset(in: text)
            for (index, token) in tokens.enumerated() where !token.isLineBreak {
                let length = token.runs.reduce(0) { $0 + $1.text.utf16.count }
                if token.id < end, token.id + length > start {
                    highlighted.insert(index)
                }
            }
        }
        self.highlighted = highlighted
        hasReadings = tokens.contains { token in token.runs.contains { $0.reading != nil } }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                if line.isEmpty {
                    TokenView(runs: [.init(text: " ", reading: nil)], reservesSpace: false, showsReadings: false)
                } else {
                    FlowLayout {
                        ForEach(line, id: \.self) { index in
                            tokenView(index)
                        }
                    }
                }
            }
        }
        .coordinateSpace(.named(Self.space))
        .gesture(selectionGesture, including: onSelect == nil ? .subviews : .all)
        .sensoryFeedback(.selection, trigger: anchor) { _, new in new != nil }
    }

    private func tokenView(_ index: Int) -> some View {
        let token = tokens[index]
        let isSelected = selection?.contains(index) == true
        return TokenView(
            runs: token.runs,
            // Only words with a reading are taller, so lines of English or kana stay compact.
            reservesSpace: showsReadings && token.runs.contains { $0.reading != nil },
            showsReadings: showsReadings && !Furigana.isForm(of: knownWords, token),
            isHighlighted: highlighted.contains(index)
        )
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(theme.accent.opacity(isSelected ? 0.4 : 0))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if let lookupText = token.lookupText {
                onWordTap(lookupText)
            }
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.space)) } action: { frames[index] = $0 }
    }

    // MARK: - Highlighting

    private static let space = "furiganaText"

    /// Hold on a word, then drag across the words to look up together.
    private var selectionGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.space)))
            .onChanged { value in
                guard case .second(true, let drag?) = value,
                      let start = anchor ?? token(at: drag.startLocation),
                      let current = token(at: drag.location)
                else { return }
                anchor = start
                selection = min(start, current)...max(start, current)
            }
            .onEnded { _ in
                if let selection {
                    let text = tokens[selection].map { $0.runs.map(\.text).joined() }.joined()
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !text.isEmpty {
                        onSelect?(text)
                    }
                }
                anchor = nil
                // Keep the highlight briefly so it's clear what was looked up.
                Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    selection = nil
                }
            }
    }

    /// The token under `point`, or the nearest one on the same line when between words.
    private func token(at point: CGPoint) -> Int? {
        if let hit = frames.first(where: { $0.value.contains(point) })?.key {
            return hit
        }
        let sameLine = frames.filter { $0.value.minY <= point.y && point.y <= $0.value.maxY }
        let candidates = sameLine.isEmpty ? frames : sameLine
        return candidates.min { distance($0.value, point) < distance($1.value, point) }?.key
    }

    private func distance(_ rect: CGRect, _ point: CGPoint) -> CGFloat {
        hypot(max(rect.minX - point.x, 0, point.x - rect.maxX), max(rect.minY - point.y, 0, point.y - rect.maxY))
    }
}

private struct TokenView: View {
    let runs: [FuriganaToken.Run]
    /// Keep room above the text so this word lines up with words that do show readings.
    let reservesSpace: Bool
    let showsReadings: Bool
    var isHighlighted = false

    private static let readingSize: CGFloat = 10

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(runs.enumerated()), id: \.offset) { _, run in
                Text(run.text)
                    .fontWeight(isHighlighted ? .bold : nil)
                    .foregroundStyle(isHighlighted ? AnyShapeStyle(.tint) : AnyShapeStyle(.foreground))
                    .fixedSize()
                    // Space for the reading is reserved on every word so lines line up,
                    // and the reading is an overlay so a long one doesn't push words apart.
                    .padding(.top, reservesSpace ? Self.readingSize + 2 : 0)
                    .overlay(alignment: .top) {
                        if showsReadings, let reading = run.reading {
                            Text(reading)
                                .font(.system(size: Self.readingSize))
                                .opacity(0.75)
                                .fixedSize()
                        }
                    }
            }
        }
    }
}

/// Places subviews left to right, wrapping to a new line when the width runs out.
/// Used for the words of a message and for the chip row under it.
struct FlowLayout: Layout {
    var spacing: CGFloat = 0
    var lineSpacing: CGFloat = 0

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, maxWidth: proposal.width ?? .infinity)
        let height = rows.reduce(0) { $0 + $1.height } + lineSpacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + row.height - size.height),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(_ subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows = [Row()]
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let gap = rows[rows.count - 1].indices.isEmpty ? 0 : spacing
            if rows[rows.count - 1].width + gap + size.width > maxWidth, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            let row = rows.count - 1
            rows[row].width += (rows[row].indices.isEmpty ? 0 : spacing) + size.width
            rows[row].indices.append(index)
            rows[row].height = max(rows[row].height, size.height)
        }
        return rows
    }
}

extension EnvironmentValues {
    /// Dictionary forms of deck words known well, whose furigana is hidden. Empty when fading is off.
    @Entry var knownWords: Set<String> = []
}
