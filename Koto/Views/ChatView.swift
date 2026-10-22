import SwiftData
import SwiftUI

struct ChatView: View {
    @State private var model = ChatViewModel()
    @State private var selectedVocab: VocabItem?

    /// Sample sentences so the fake bot's corrections can be tried without a Japanese keyboard.
    private let samples = [
        "こんにちは！",
        "昨日友達と映画を見に行きました",
        "私わ学生です",
        "ありがとうございます",
        "元気ですか？",
    ]

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 14) {
                        Text("今日")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.2), in: Capsule())
                            .padding(.top, 4)

                        ForEach(model.messages) { message in
                            MessageRow(message: message) { selectedVocab = $0 }
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
                VStack(spacing: 0) {
                    SampleChips(samples: samples, isDisabled: model.isBotTyping) { model.send($0) }
                    InputBar(text: $model.draft, canSend: model.canSend) { model.send() }
                }
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
        }
    }
}

private struct SampleChips: View {
    let samples: [String]
    let isDisabled: Bool
    let onTap: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text("Try:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(samples, id: \.self) { sample in
                    Button(sample) { onTap(sample) }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.secondarySystemBackground), in: Capsule())
                        .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }
}

#Preview {
    ChatView()
        .modelContainer(for: SavedWord.self, inMemory: true)
}
