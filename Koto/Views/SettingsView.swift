import SwiftData
import SwiftUI

struct SettingsView: View {
    /// Called after a backup is imported, so the open chat can reload.
    var onImported: () -> Void = {}

    @AppStorage(AppSettings.strictnessKey) private var strictness = CorrectionStrictness.balanced
    @AppStorage(AppSettings.furiganaKey) private var showFurigana = true
    @AppStorage(AppSettings.fadeKnownFuriganaKey) private var fadeKnownFurigana = true
    @AppStorage(AppSettings.slowSpeechKey) private var slowSpeech = true
    @AppStorage(AppSettings.reminderKey) private var reminder = false
    @AppStorage(AppSettings.reminderMinutesKey) private var reminderMinutes = AppSettings.defaultReminderMinutes
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var exportDocument: BackupDocument?
    @State private var isImporting = false
    @State private var backupMessage: String?

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
                    Toggle("Daily lesson reminder", isOn: $reminder)
                    if reminder {
                        DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("Learn")
                } footer: {
                    Text("A notification for the daily grammar lesson. Skipped on days you've already done it.")
                }
                .onChange(of: reminder) {
                    Task {
                        if reminder, !(await Reminders.requestPermission()) {
                            // Notifications are turned off for Koto in iOS Settings.
                            reminder = false
                        }
                        Reminders.reschedule(context: context)
                    }
                }
                .onChange(of: reminderMinutes) { Reminders.reschedule(context: context) }

                Section {
                    Button("Export backup", systemImage: "square.and.arrow.up") { export() }
                    Button("Import backup", systemImage: "square.and.arrow.down") { isImporting = true }
                } header: {
                    Text("Backup")
                } footer: {
                    Text("Saves your words and grammar (with review history), mistakes, course progress and all chats to a file in the Files app, so you keep them if the app is deleted. Importing adds what's missing and never deletes anything.")
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
            .fileExporter(
                isPresented: Binding(get: { exportDocument != nil }, set: { if !$0 { exportDocument = nil } }),
                document: exportDocument,
                contentType: .json,
                defaultFilename: "Koto backup \(Date.now.formatted(.iso8601.year().month().day()))"
            ) { result in
                if case .failure(let error) = result {
                    backupMessage = "Couldn't save the backup: \(error.localizedDescription)"
                }
            }
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
                importBackup(result)
            }
            .alert("Backup", isPresented: Binding(get: { backupMessage != nil }, set: { if !$0 { backupMessage = nil } })) {
                Button("OK") {}
            } message: {
                Text(backupMessage ?? "")
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    /// The reminder time as a date today, for the time picker.
    private var reminderTime: Binding<Date> {
        Binding {
            Calendar.current.startOfDay(for: .now).addingTimeInterval(TimeInterval(reminderMinutes * 60))
        } set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            reminderMinutes = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        }
    }

    private func export() {
        do {
            exportDocument = BackupDocument(data: try Backup(from: context).encoded())
        } catch {
            backupMessage = "Couldn't create the backup: \(error.localizedDescription)"
        }
    }

    private func importBackup(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            // Files from the Files app are outside the sandbox until we ask for access.
            let didAccess = url.startAccessingSecurityScopedResource()
            defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
            let summary = try Backup.decode(Data(contentsOf: url)).merge(into: context)
            onImported()
            backupMessage = "Imported \(summary.wordsAdded) new words (updated \(summary.wordsUpdated)), "
                + "\(summary.grammarAdded) grammar patterns, \(summary.lessonsAdded) course lessons and \(summary.messagesAdded) messages."
        } catch {
            backupMessage = "Couldn't import: \(error.localizedDescription)"
        }
    }
}

#Preview {
    SettingsView()
}
