import SwiftUI

struct VocabDetailSheet: View {
    let item: VocabItem

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

            // The vocab deck + spaced repetition come in a later step.
            Button("Add to my words") {}
                .buttonStyle(.borderedProminent)
                .disabled(true)
                .padding(.top, 6)
            Text("Coming soon")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
