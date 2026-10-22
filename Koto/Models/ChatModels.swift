import Foundation

nonisolated enum Sender {
    case user
    case bot
}

nonisolated struct ChatMessage: Identifiable, Equatable {
    var id = UUID()
    let sender: Sender
    let text: String
    var date = Date()
    /// Corrections the bot made to this (user) message.
    var corrections: [Correction] = []
    /// Words the bot highlighted in this (bot) message.
    var vocab: [VocabItem] = []
    /// Shows 既読 next to a user message once the bot has replied.
    var isRead = false
    /// An error shown in the chat. Not saved, and not sent to the bot as history.
    var isError = false
}

/// What the bot returns for each user message.
/// Mirrors the JSON the real LLM will be asked to produce, so swapping
/// FakeChatService for a real one doesn't change the UI.
nonisolated struct BotResponse: Codable {
    let reply: String
    let corrections: [Correction]
    let newVocab: [VocabItem]

    enum CodingKeys: String, CodingKey {
        case reply
        case corrections
        case newVocab = "new_vocab"
    }
}

nonisolated struct Correction: Codable, Hashable {
    enum Kind: String, Codable {
        /// Actually wrong (particles, conjugation, spelling).
        case grammar
        /// Correct, but a native speaker wouldn't say it that way.
        case naturalness
        /// Too formal or too casual for the situation.
        case register

        var label: String {
            switch self {
            case .grammar: "Grammar"
            case .naturalness: "Naturalness"
            case .register: "Register"
            }
        }
    }

    let original: String
    /// nil when there's no single rewrite to suggest.
    let suggested: String?
    let type: Kind
    let explanation: String
}

nonisolated struct VocabItem: Codable, Hashable, Identifiable {
    var id: String { word }
    let word: String
    let reading: String
    let meaning: String
}
