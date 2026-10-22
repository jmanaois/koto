import SwiftUI

struct VocabDetailSheet: View {
    let item: VocabItem
    var example: ExampleSentence?

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Text(item.word)
                    .font(.largeTitle.bold())
                SpeakButton(text: item.reading)
            }
            if item.reading != item.word {
                Text(item.reading)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Text(item.meaning)
                .font(.body)
                .multilineTextAlignment(.center)

            SaveWordButton(item: item, example: example)
                .padding(.top, 6)
        }
        .padding()
    }
}
