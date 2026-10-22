import SwiftUI

/// Collapsed "✏️ 2 fixes" pill under a user message that expands into correction cards.
struct CorrectionsView: View {
    let corrections: [Correction]
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Button {
                withAnimation(.snappy) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "pencil.line")
                    Text(corrections.count == 1 ? "1 fix" : "\(corrections.count) fixes")
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.white.opacity(0.9), in: Capsule())
                .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(corrections, id: \.self) { correction in
                    CorrectionCard(correction: correction)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
}

private struct CorrectionCard: View {
    let correction: Correction

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(correction.type.label)
                .font(.caption2.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(tint)

            Text(correction.original)
                .strikethrough(correction.suggested != nil)
                .foregroundStyle(.secondary)

            if let suggested = correction.suggested {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.turn.down.right")
                        .foregroundStyle(tint)
                    Text(suggested)
                        .fontWeight(.semibold)
                }
            }

            Text(correction.explanation)
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.botBubble, in: RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .leading) {
            UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 12)
                .fill(tint)
                .frame(width: 4)
        }
    }

    private var tint: Color {
        switch correction.type {
        case .grammar: .red
        case .naturalness: .orange
        case .register: .blue
        }
    }
}
