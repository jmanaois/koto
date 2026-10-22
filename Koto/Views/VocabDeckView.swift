import SwiftData
import SwiftUI

/// The user's saved words, newest first.
struct VocabDeckView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SavedWord.addedAt, order: .reverse) private var words: [SavedWord]

    var body: some View {
        List {
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
                    }
                    Text(word.meaning)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
            .onDelete { offsets in
                for index in offsets {
                    context.delete(words[index])
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
}

#Preview {
    NavigationStack {
        VocabDeckView()
    }
    .modelContainer(for: SavedWord.self, inMemory: true)
}
