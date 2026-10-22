import Foundation
import Observation
import SwiftData

@Observable
final class ChatViewModel {
    private(set) var messages: [ChatMessage] = []
    var draft = ""
    private(set) var isBotTyping = false

    private let service: ChatService
    private let context: ModelContext
    /// Saved copies of `messages`, by id, so later changes can be written back.
    private var stored: [UUID: StoredMessage] = [:]

    init(context: ModelContext, service: ChatService = FakeChatService()) {
        self.context = context
        self.service = service

        let saved = (try? context.fetch(FetchDescriptor<StoredMessage>(sortBy: [SortDescriptor(\.date)]))) ?? []
        for message in saved {
            stored[message.id] = message
        }
        messages = saved.map(\.chatMessage)

        if messages.isEmpty {
            append(ChatMessage(sender: .bot, text: "やっほー！ことだよ👋\n日本語でなんでも話しかけてね。変なところがあったら直すよ！"))
        }
    }

    var canSend: Bool {
        !isBotTyping && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Sends `text` if given (e.g. from a sample chip), otherwise the current draft.
    func send(_ text: String? = nil) {
        let body = (text ?? draft).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, !isBotTyping else { return }
        if text == nil { draft = "" }

        append(ChatMessage(sender: .user, text: body))
        let userIndex = messages.count - 1
        isBotTyping = true

        Task {
            defer { isBotTyping = false }
            do {
                let response = try await service.reply(to: messages)
                update(at: userIndex) {
                    $0.corrections = response.corrections
                    $0.isRead = true
                }
                append(ChatMessage(sender: .bot, text: response.reply, vocab: response.newVocab))
            } catch {
                append(ChatMessage(sender: .bot, text: "ごめん、エラーが出ちゃった🙏 もう一回送ってみて！"))
            }
        }
    }

    // MARK: - Persistence

    private func append(_ message: ChatMessage) {
        messages.append(message)
        let saved = StoredMessage(message)
        context.insert(saved)
        stored[message.id] = saved
        save()
    }

    private func update(at index: Int, _ change: (inout ChatMessage) -> Void) {
        change(&messages[index])
        stored[messages[index].id]?.update(from: messages[index])
        save()
    }

    private func save() {
        try? context.save()
    }
}
