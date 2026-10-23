import SwiftData
import SwiftUI

/// The user's saved words, newest first, with a way into review.
struct VocabDeckView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SavedWord.addedAt, order: .reverse) private var words: [SavedWord]

    private var dueCount: Int {
        words.filter { $0.dueAt <= .now }.count
    }

    var body: some View {
        List {
            if !words.isEmpty {
                Section {
                    ReviewRow<SavedWord>(dueCount: dueCount)
                }
            }

            Section {
                ForEach(words) { word in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(word.word)
                                .font(.headline)
                            if word.reading != word.word {
                                Text(word.reading)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            dueLabel(for: word)
                        }
                        Text(word.meaning)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let sentence = word.exampleSentence {
                            Text(Self.emphasizing(word.word, in: sentence))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onDelete { offsets in
                    for index in offsets {
                        context.delete(words[index])
                    }
                }
            }
        }
        .overlay {
            if words.isEmpty {
                ContentUnavailableView(
                    "No words yet",
                    systemImage: "book.closed",
                    description: Text("Tap a word under こと's messages to save it here.")
                )
            }
        }
    }

    /// The sentence with the saved word (or its conjugated form) in bold.
    static func emphasizing(_ word: String, in sentence: String) -> AttributedString {
        var text = AttributedString(sentence)
        if let range = Furigana.occurrence(of: word, in: sentence),
           let start = AttributedString.Index(range.lowerBound, within: text),
           let end = AttributedString.Index(range.upperBound, within: text) {
            text[start..<end].inlinePresentationIntent = .stronglyEmphasized
        }
        return text
    }

    private func dueLabel(for word: SavedWord) -> some View {
        DueLabel(dueAt: word.dueAt, isKnown: word.isKnownWell)
    }
}

/// "Due", "Known", or when the card is next due.
struct DueLabel: View {
    let dueAt: Date
    var isKnown = false

    var body: some View {
        Group {
            if isKnown, dueAt > .now {
                // Not a Label: inside a List it pads the icon like a row icon.
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.seal.fill")
                    Text("Known")
                }
                .foregroundStyle(.green)
            } else if dueAt <= .now {
                Text("Due")
                    .foregroundStyle(Color.accentColor)
            } else {
                Text(dueAt, format: .relative(presentation: .numeric))
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
    }
}

/// The Review row at the top of a deck.
struct ReviewRow<Card: ReviewCard>: View {
    let dueCount: Int

    var body: some View {
        NavigationLink {
            ReviewView<Card>()
        } label: {
            HStack {
                Label("Review", systemImage: "rectangle.stack")
                Spacer()
                Text(dueCount == 0 ? "All caught up" : "\(dueCount) due")
                    .foregroundStyle(dueCount == 0 ? Color.secondary : Color.accentColor)
            }
        }
    }
}

#Preview {
    NavigationStack {
        VocabDeckView()
    }
    .modelContainer(for: SavedWord.self, inMemory: true)
}
