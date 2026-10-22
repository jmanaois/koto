import SwiftUI

/// Message text with furigana over the kanji. Words wrap like normal text,
/// and tapping a Japanese word calls `onWordTap` with the text to look up.
struct FuriganaText: View {
    let onWordTap: (String) -> Void
    /// Tokens grouped into lines at each line break.
    private let lines: [[FuriganaToken]]
    /// Only reserve space above the text when something has a reading.
    private let hasReadings: Bool

    init(_ text: String, onWordTap: @escaping (String) -> Void) {
        self.onWordTap = onWordTap
        let tokens = Furigana.tokens(for: text)
        var lines: [[FuriganaToken]] = [[]]
        for token in tokens {
            if token.isLineBreak {
                lines.append([])
            } else {
                lines[lines.count - 1].append(token)
            }
        }
        self.lines = lines
        hasReadings = tokens.contains { token in token.runs.contains { $0.reading != nil } }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                if line.isEmpty {
                    TokenView(runs: [.init(text: " ", reading: nil)], showsReadings: hasReadings)
                } else {
                    FlowLayout {
                        ForEach(line) { token in
                            TokenView(runs: token.runs, showsReadings: hasReadings)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if let lookupText = token.lookupText {
                                        onWordTap(lookupText)
                                    }
                                }
                        }
                    }
                }
            }
        }
    }
}

private struct TokenView: View {
    let runs: [FuriganaToken.Run]
    let showsReadings: Bool

    private static let readingSize: CGFloat = 10

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(runs.enumerated()), id: \.offset) { _, run in
                Text(run.text)
                    .fixedSize()
                    // Space for the reading is reserved on every word so lines line up,
                    // and the reading is an overlay so a long one doesn't push words apart.
                    .padding(.top, showsReadings ? Self.readingSize + 2 : 0)
                    .overlay(alignment: .top) {
                        if let reading = run.reading {
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
