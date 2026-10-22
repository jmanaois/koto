import Foundation
import SwiftData

/// A chat message saved on device so the conversation survives app restarts.
@Model
final class StoredMessage {
    @Attribute(.unique) var id: UUID
    var isFromUser: Bool
    var text: String
    var date: Date
    var isRead: Bool
    // JSON-encoded [Correction] and [VocabItem]. Kept as plain data so the
    // SwiftData schema doesn't depend on the shape of those structs.
    var correctionsData: Data
    var vocabData: Data

    init(_ message: ChatMessage) {
        id = message.id
        isFromUser = message.sender == .user
        text = message.text
        date = message.date
        isRead = message.isRead
        correctionsData = Data()
        vocabData = Data()
        update(from: message)
    }

    /// Copies the fields that can change after a message is sent.
    func update(from message: ChatMessage) {
        isRead = message.isRead
        correctionsData = (try? JSONEncoder().encode(message.corrections)) ?? Data()
        vocabData = (try? JSONEncoder().encode(message.vocab)) ?? Data()
    }

    var chatMessage: ChatMessage {
        ChatMessage(
            id: id,
            sender: isFromUser ? .user : .bot,
            text: text,
            date: date,
            corrections: (try? JSONDecoder().decode([Correction].self, from: correctionsData)) ?? [],
            vocab: (try? JSONDecoder().decode([VocabItem].self, from: vocabData)) ?? [],
            isRead: isRead
        )
    }
}
