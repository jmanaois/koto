import SwiftData
import SwiftUI

struct ChatView: View {
    @Bindable var model: ChatViewModel
    @State private var selectedVocab: VocabSelection?
    @State private var wordLookup: WordLookup?
    @State private var translating: TranslationTarget?
    @State private var showingSettings = false
    @State private var confirmingClear = false
    @Query private var savedWords: [SavedWord]
    @AppStorage(AppSettings.fadeKnownFuriganaKey) private var fadeKnownFurigana = true

    private var knownWords: Set<String> {
        fadeKnownFurigana ? Set(savedWords.filter(\.isKnownWell).map(\.word)) : []
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(Array(model.messages.enumerated()), id: \.element.id) { index, message in
                            if index == 0 || !Calendar.current.isDate(message.date, inSameDayAs: model.messages[index - 1].date) {
                                DatePill(date: message.date)
                            }
                            MessageRow(
                                message: message,
                                persona: model.mode.persona(for: message.speaker),
                                onVocabTap: { selectedVocab = VocabSelection(item: $0, message: message) },
                                onWordTap: { wordLookup = WordLookup(text: $0, in: message) },
                                onSelect: { wordLookup = WordLookup(text: $0, in: message, isSelection: true) },
                                onTranslate: { translating = TranslationTarget(id: message.id) }
                            )
                            .id(message.id)
                        }

                        if model.isBotTyping {
                            TypingIndicatorRow(persona: model.mode.persona(for: nil))
                                .id("typing")
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .defaultScrollAnchor(.bottom)
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: model.messages.count) {
                    withAnimation { proxy.scrollTo(model.messages.last?.id, anchor: .bottom) }
                }
                .onChange(of: model.isBotTyping) {
                    if model.isBotTyping {
                        withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                    }
                }
            }
            .background(Theme.chatBackground)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                InputBar(text: $model.draft, canSend: model.canSend) { model.send() }
                    .background(.bar)
            }
            .navigationTitle(model.mode.chatTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Settings", systemImage: "gearshape") { showingSettings = true }
                }
                ToolbarItem(placement: .principal) {
                    ModeMenu(mode: $model.mode, canClear: !model.isBotTyping) { confirmingClear = true }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        VocabDeckView()
                    } label: {
                        Label("My words", systemImage: "book")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(onImported: { model.reload() })
            }
            .confirmationDialog(
                "Clear this chat?",
                isPresented: $confirmingClear,
                titleVisibility: .visible
            ) {
                Button("Clear chat with \(model.mode.chatTitle)", role: .destructive) {
                    model.clearChat()
                }
            } message: {
                Text("Deletes the messages in this chat and starts it over. Your saved words and other chats are kept.")
            }
            .sheet(item: $selectedVocab) { selection in
                VocabDetailSheet(item: selection.item, example: selection.example)
                    .presentationDetents([.height(260)])
            }
            .sheet(item: $wordLookup) { lookup in
                WordLookupSheet(lookup: lookup)
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $translating) { target in
                if let message = model.messages.first(where: { $0.id == target.id }) {
                    ExplanationSheet(message: message) { try await model.explain(target.id) }
                        .presentationDetents([.medium, .large])
                }
            }
        }
        .environment(\.knownWords, knownWords)
    }
}

/// The chat title, which opens a menu for switching who you're talking to.
private struct ModeMenu: View {
    @Binding var mode: ChatMode
    let canClear: Bool
    let onClear: () -> Void

    var body: some View {
        Menu {
            Picker("Chat with", selection: $mode) {
                ForEach(ChatMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.systemImage)
                        .tag(mode)
                }
            }
            Section {
                Button("Clear this chat…", systemImage: "trash", role: .destructive, action: onClear)
                    .disabled(!canClear)
            }
        } label: {
            HStack(spacing: 4) {
                Text(mode.chatTitle)
                    .font(.headline)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.primary)
        }
        .accessibilityLabel("Chat mode: \(mode.title)")
    }
}

/// A highlighted word tapped under a bot message, with the sentence it came from.
private struct VocabSelection: Identifiable {
    let item: VocabItem
    let example: ExampleSentence?
    var id: String { item.id }

    init(item: VocabItem, message: ChatMessage) {
        self.item = item
        example = ExampleSentence(from: message, containing: item.word)
    }
}

/// The bot message whose translation sheet is open.
private struct TranslationTarget: Identifiable {
    let id: UUID
}

/// LINE-style day separator: 今日, 昨日, or a date like 10月20日(月).
private struct DatePill: View {
    let date: Date

    private var label: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "今日" }
        if calendar.isDateInYesterday(date) { return "昨日" }
        return date.formatted(.dateTime.month().day().weekday(.abbreviated).locale(Locale(identifier: "ja_JP")))
    }

    var body: some View {
        Text(label)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.black.opacity(0.2), in: Capsule())
            .padding(.top, 4)
    }
}

#Preview {
    let container = try! ModelContainer(
        for: SavedWord.self, StoredMessage.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    ChatView(model: ChatViewModel(context: container.mainContext, service: FakeChatService()))
        .modelContainer(container)
}
