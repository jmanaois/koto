import Foundation
import SwiftData

/// A chat message saved on device so the conversation survives app restarts.
@Model
final class StoredMessage {
    @Attribute(.unique) var id: UUID
    var isFromUser: Bool
    var text: String
    var speaker: String?
    /// The ChatMode this message belongs to; nil for messages saved before modes existed (friend).
    var mode: String?
    var date: Date
    var isRead: Bool
    // JSON-encoded corrections, vocab, practiced words and explanation. Kept as plain
    // data so the SwiftData schema doesn't depend on the shape of those structs.
    var correctionsData: Data
    var vocabData: Data
    var practicedData = Data()
    var explanationData: Data?
    var grammarData: Data?

    init(_ message: ChatMessage, mode: ChatMode) {
        id = message.id
        isFromUser = message.sender == .user
        text = message.text
        speaker = message.speaker
        self.mode = mode.rawValue
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
        practicedData = (try? JSONEncoder().encode(message.practicedWords)) ?? Data()
        explanationData = message.explanation.flatMap { try? JSONEncoder().encode($0) }
        grammarData = message.grammar.flatMap { try? JSONEncoder().encode($0) }
    }

    var chatMessage: ChatMessage {
        ChatMessage(
            id: id,
            sender: isFromUser ? .user : .bot,
            text: text,
            speaker: speaker,
            date: date,
            corrections: (try? JSONDecoder().decode([Correction].self, from: correctionsData)) ?? [],
            vocab: (try? JSONDecoder().decode([VocabItem].self, from: vocabData)) ?? [],
            grammar: grammarData.flatMap { try? JSONDecoder().decode(GrammarPoint.self, from: $0) },
            isRead: isRead,
            practicedWords: (try? JSONDecoder().decode([String].self, from: practicedData)) ?? [],
            explanation: explanationData.flatMap { try? JSONDecoder().decode(MessageExplanation.self, from: $0) }
        )
    }
}
