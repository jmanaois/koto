import SwiftData
import SwiftUI

struct VocabDetailSheet: View {
    let item: VocabItem

    @Environment(\.modelContext) private var context
    @Query private var savedWords: [SavedWord]

    private var savedWord: SavedWord? {
        savedWords.first { $0.word == item.word }
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(item.word)
                .font(.largeTitle.bold())
            if item.reading != item.word {
                Text(item.reading)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Text(item.meaning)
                .font(.body)
                .multilineTextAlignment(.center)

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
            .padding(.top, 6)
        }
        .padding()
        .sensoryFeedback(.success, trigger: savedWord != nil) { _, isSaved in isSaved }
    }
}
