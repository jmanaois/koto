import SwiftUI

/// A speaker icon that reads `text` aloud; tap again to stop.
struct SpeakButton: View {
    let text: String
    var font: Font = .title3

    private var isSpeaking: Bool { Speech.shared.speakingText == text }

    var body: some View {
        Button {
            Speech.shared.toggle(text)
        } label: {
            Image(systemName: isSpeaking ? "stop.circle.fill" : "speaker.wave.2.fill")
                .font(font)
                .symbolEffect(.variableColor.iterative, options: .repeating, isActive: isSpeaking)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(isSpeaking ? "Stop" : "Listen")
    }
}
