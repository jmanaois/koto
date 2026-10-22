import SwiftData
import SwiftUI

/// "Add to my words", or "In my words" with a Remove option once saved.
struct SaveWordButton: View {
    let item: VocabItem

    @Environment(\.modelContext) private var context
    @Query private var savedWords: [SavedWord]

    private var savedWord: SavedWord? {
        savedWords.first { $0.word == item.word }
    }

    var body: some View {
        Group {
            if let savedWord {
                VStack(spacing: 6) {
                    Label("In my words", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.headline)
                    Button("Remove", role: .destructive) {
                        context.delete(savedWord)
                    }
                    .font(.footnote)
                }
            } else {
                Button("Add to my words", systemImage: "plus") {
                    context.insert(SavedWord(item))
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .sensoryFeedback(.success, trigger: savedWord != nil) { _, isSaved in isSaved }
    }
}
