import SwiftData
import SwiftUI

struct ChatView: View {
    @Bindable var model: ChatViewModel
    @State private var selectedVocab: VocabItem?
    @State private var wordLookup: WordLookup?

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
                                onVocabTap: { selectedVocab = $0 },
                                onWordTap: { wordLookup = WordLookup(text: $0) }
                            )
                            .id(message.id)
                        }

                        if model.isBotTyping {
                            TypingIndicatorRow()
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
            .navigationTitle("こと")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        VocabDeckView()
                    } label: {
                        Label("My words", systemImage: "book")
                    }
                }
            }
            .sheet(item: $selectedVocab) { item in
                VocabDetailSheet(item: item)
                    .presentationDetents([.height(260)])
            }
            .sheet(item: $wordLookup) { lookup in
                WordLookupSheet(lookup: lookup)
                    .presentationDetents([.medium, .large])
            }
        }
    }
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
