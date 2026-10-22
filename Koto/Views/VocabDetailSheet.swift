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

            SaveWordButton(item: item)
                .padding(.top, 6)
        }
        .padding()
    }
}
