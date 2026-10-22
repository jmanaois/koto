import Foundation
import Observation

@Observable
final class ChatViewModel {
    private(set) var messages: [ChatMessage] = [
        ChatMessage(sender: .bot, text: "やっほー！ことだよ👋\n日本語でなんでも話しかけてね。変なところがあったら直すよ！"),
    ]
    var draft = ""
    private(set) var isBotTyping = false

    private let service: ChatService

    init(service: ChatService = FakeChatService()) {
        self.service = service
    }

    var canSend: Bool {
        !isBotTyping && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Sends `text` if given (e.g. from a sample chip), otherwise the current draft.
    func send(_ text: String? = nil) {
        let body = (text ?? draft).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, !isBotTyping else { return }
        if text == nil { draft = "" }

        messages.append(ChatMessage(sender: .user, text: body))
        let userIndex = messages.count - 1
        isBotTyping = true

        Task {
            defer { isBotTyping = false }
            do {
                let response = try await service.reply(to: messages)
                messages[userIndex].corrections = response.corrections
                messages[userIndex].isRead = true
                messages.append(ChatMessage(sender: .bot, text: response.reply, vocab: response.newVocab))
            } catch {
                messages.append(ChatMessage(sender: .bot, text: "ごめん、エラーが出ちゃった🙏 もう一回送ってみて！"))
            }
        }
    }
}
