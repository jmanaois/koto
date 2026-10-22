import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.strictnessKey) private var strictness = CorrectionStrictness.balanced
    @AppStorage(AppSettings.furiganaKey) private var showFurigana = true
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
                } header: {
                    Text("Reading")
                } footer: {
                    Text("Readings above kanji in chat, translations and flashcards. Tap any word to look it up either way.")
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
