import SwiftUI

/// Message text with furigana over the kanji. Words wrap like normal text.
/// Tapping a Japanese word calls `onWordTap` with the text to look up; pressing and
/// dragging across words highlights them and calls `onSelect` with the highlighted text.
struct FuriganaText: View {
    let onWordTap: (String) -> Void
    var onSelect: ((String) -> Void)?

    private let tokens: [FuriganaToken]
    /// Indices into `tokens`, grouped into lines at each line break.
    private let lines: [[Int]]
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

    init(_ text: String, onWordTap: @escaping (String) -> Void, onSelect: ((String) -> Void)? = nil) {
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
        hasReadings = tokens.contains { token in token.runs.contains { $0.reading != nil } }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                if line.isEmpty {
                    TokenView(runs: [.init(text: " ", reading: nil)], reservesSpace: showsReadings, showsReadings: false)
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
            reservesSpace: showsReadings,
            showsReadings: showsReadings && !Furigana.isForm(of: knownWords, token)
        )
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.accentColor.opacity(isSelected ? 0.4 : 0))
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

    private static let readingSize: CGFloat = 10

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(runs.enumerated()), id: \.offset) { _, run in
                Text(run.text)
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
private struct FlowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, maxWidth: proposal.width ?? .infinity)
        return CGSize(width: rows.map(\.width).max() ?? 0, height: rows.reduce(0) { $0 + $1.height })
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
                x += size.width
            }
            y += row.height
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
            if rows[rows.count - 1].width + size.width > maxWidth, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            rows[rows.count - 1].indices.append(index)
            rows[rows.count - 1].width += size.width
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
        }
        return rows
    }
}

extension EnvironmentValues {
    /// Dictionary forms of deck words known well, whose furigana is hidden. Empty when fading is off.
    @Entry var knownWords: Set<String> = []
}
