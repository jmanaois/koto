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
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("In my words")
                    }
                    .foregroundStyle(.green)
                    .font(.headline)
                    Button("Remove", role: .destructive) {
                        context.delete(savedWord)
                    }
                    .font(.footnote)
                }
            } else {
                Button {
                    context.insert(SavedWord(item))
                } label: {
                    // Not a Label (here or above): inside a List, Label tints its icon
                    // with the accent color and pads it like a list icon.
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Add to my words")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .sensoryFeedback(.success, trigger: savedWord != nil) { _, isSaved in isSaved }
    }
}
