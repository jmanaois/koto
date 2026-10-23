import SwiftData
import SwiftUI

/// Flashcard review of due cards (saved words or grammar). Shows the front, then the
/// reading and meaning, and the user rates how well they remembered it.
struct ReviewView<Card: ReviewCard>: View {
    @Query private var words: [Card]

    /// Snapshot of due cards taken when the session starts. Cards rated Again go to the back.
    @State private var queue: [Card] = []
    @State private var hasStarted = false
    @State private var isShowingAnswer = false
    @State private var reviewedCount = 0

    var body: some View {
        Group {
            if let card = queue.first {
                cardView(card)
            } else if hasStarted {
                doneView
            } else {
                // Needs to be a real view so onAppear fires and builds the queue.
                Color.clear
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !hasStarted else { return }
            queue = words.filter { $0.dueAt <= .now }.sorted { $0.dueAt < $1.dueAt }
            hasStarted = true
        }
    }

    private func cardView(_ card: Card) -> some View {
        VStack(spacing: 20) {
            Text("\(queue.count) left")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                Text(card.cardFront)
                    .font(.system(size: 44, weight: .bold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                if isShowingAnswer {
                    SpeakButton(text: card.cardSpeech)
                    Divider()
                    if let reading = card.cardReading {
                        Text(reading)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    Text(card.cardMeaning)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                    if let note = card.cardNote {
                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    if let sentence = card.cardExample {
                        VStack(spacing: 4) {
                            HStack(alignment: .center, spacing: 8) {
                                FuriganaText(sentence, highlighting: card.cardHighlight, onWordTap: { _ in })
                                SpeakButton(text: sentence, font: .body)
                            }
                            if let translation = card.cardExampleTranslation {
                                Text(translation)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 280)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))

            Spacer()

            if isShowingAnswer {
                HStack(spacing: 8) {
                    ForEach(FSRS.Rating.allCases, id: \.self) { rating in
                        Button {
                            rate(card, rating)
                        } label: {
                            VStack(spacing: 2) {
                                Text(rating.label)
                                    .font(.headline)
                                Text(Self.format(card.preview(rating).interval))
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .tint(Self.tint(for: rating))
                    }
                }
            } else {
                Button {
                    withAnimation(.snappy) { isShowingAnswer = true }
                } label: {
                    Text("Show answer")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    private var doneView: some View {
        let nextDue = words.map(\.dueAt).min()
        return ContentUnavailableView {
            Label("お疲れさま！", systemImage: "checkmark.seal")
        } description: {
            VStack(spacing: 4) {
                Text(reviewedCount == 0 ? "Nothing is due right now." : "You finished today's reviews.")
                if let nextDue, nextDue > .now {
                    Text("Next review \(nextDue, format: .relative(presentation: .named)).")
                }
            }
        }
    }

    private func rate(_ card: Card, _ rating: FSRS.Rating) {
        card.review(rating)
        reviewedCount += 1
        withAnimation(.snappy) {
            isShowingAnswer = false
            queue.removeFirst()
            if rating == .again {
                queue.append(card)
            }
        }
    }

    /// Short Anki-style interval label: 1m, 3h, 4d, 2mo.
    private static func format(_ interval: TimeInterval) -> String {
        let minutes = interval / 60
        let days = interval / 86_400
        switch true {
        case minutes < 60: return "\(Int(minutes.rounded()))m"
        case days < 1: return "\(Int((minutes / 60).rounded()))h"
        case days < 30: return "\(Int(days.rounded()))d"
        case days < 365: return "\(Int((days / 30).rounded()))mo"
        default: return "\(Int((days / 365).rounded()))y"
        }
    }

    private static func tint(for rating: FSRS.Rating) -> Color {
        switch rating {
        case .again: .red
        case .hard: .orange
        case .good: .green
        case .easy: .blue
        }
    }
}
