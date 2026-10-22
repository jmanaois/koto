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
                    NavigationLink {
                        ReviewView()
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
                            Text(sentence)
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
        .navigationTitle("My words")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func dueLabel(for word: SavedWord) -> some View {
        Group {
            if word.isKnownWell, word.dueAt > .now {
                // Not a Label: inside a List it pads the icon like a row icon.
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.seal.fill")
                    Text("Known")
                }
                .foregroundStyle(.green)
            } else if word.dueAt <= .now {
                Text("Due")
                    .foregroundStyle(Color.accentColor)
            } else {
                Text(word.dueAt, format: .relative(presentation: .numeric))
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
    }
}

#Preview {
    NavigationStack {
        VocabDeckView()
    }
    .modelContainer(for: SavedWord.self, inMemory: true)
}
