import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.strictnessKey) private var strictness = CorrectionStrictness.balanced
    @AppStorage(AppSettings.furiganaKey) private var showFurigana = true
    @AppStorage(AppSettings.fadeKnownFuriganaKey) private var fadeKnownFurigana = true
    @AppStorage(AppSettings.slowSpeechKey) private var slowSpeech = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Corrections", selection: $strictness) {
                        ForEach(CorrectionStrictness.allCases) { level in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.label)
                                Text(level.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Corrections")
                } footer: {
                    Text("Applies to your next message, in every chat mode.")
                }

                Section {
                    Toggle("Show furigana", isOn: $showFurigana)
                    Toggle("Hide furigana on words I know", isOn: $fadeKnownFurigana)
                        .disabled(!showFurigana)
                } header: {
                    Text("Reading")
                } footer: {
                    Text("Readings above kanji in chat, translations and flashcards. Words in My words marked Known (reviewed well several times in a row) lose their furigana so you practice reading them. Tap any word to look it up either way.")
                }

                Section {
                    Toggle("Slower speech", isOn: $slowSpeech)
                    Button("Try it", systemImage: "speaker.wave.2") {
                        Speech.shared.speak("やっほー！今日、何してたの？")
                    }
                } header: {
                    Text("Listening")
                } footer: {
                    Text("Tap the speaker under こと's messages, on word lookups and on flashcards. Or hold and drag across any words to highlight them, then tap the speaker. Uses the built-in iOS Japanese voice.")
                }

                Section {
                    LabeledContent("Model", value: ClaudeChatService.model)
                    LabeledContent("Dictionary", value: "JMdict (EDRDG, CC BY-SA 4.0)")
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
