import Foundation

nonisolated enum Sender {
    case user
    case bot
}

nonisolated struct ChatMessage: Identifiable, Equatable {
    var id = UUID()
    let sender: Sender
    let text: String
    /// Which group-chat member wrote this (bot) message; nil outside group chats.
    var speaker: String?
    var date = Date()
    /// Corrections the bot made to this (user) message.
    var corrections: [Correction] = []
    /// Words the bot highlighted in this (bot) message.
    var vocab: [VocabItem] = []
    /// A grammar pattern the bot highlighted in this (bot) message.
    var grammar: GrammarPoint?
    /// Shows 既読 next to a user message once the bot has replied.
    var isRead = false
    /// Practice words and grammar patterns the user used correctly in this (user) message;
    /// each counted as a review.
    var practicedWords: [String] = []
    /// English translation and breakdown of this (bot) message, fetched when first asked for.
    var explanation: MessageExplanation?
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
    /// Practice words the user used correctly in their latest message.
    let practicedWords: [String]
    /// A grammar pattern from the reply worth learning, if any.
    let grammar: GrammarPoint?
    /// Practice grammar patterns the user used correctly in their latest message.
    let practicedGrammar: [String]

    enum CodingKeys: String, CodingKey {
        case reply
        case corrections
        case newVocab = "new_vocab"
        case practicedWords = "practiced_words"
        case grammar
        case practicedGrammar = "practiced_grammar"
    }

    init(
        reply: String, corrections: [Correction], newVocab: [VocabItem], practicedWords: [String] = [],
        grammar: GrammarPoint? = nil, practicedGrammar: [String] = []
    ) {
        self.reply = reply
        self.corrections = corrections
        self.newVocab = newVocab
        self.practicedWords = practicedWords
        self.grammar = grammar
        self.practicedGrammar = practicedGrammar
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reply = try container.decode(String.self, forKey: .reply)
        corrections = try container.decode([Correction].self, forKey: .corrections)
        newVocab = try container.decode([VocabItem].self, forKey: .newVocab)
        practicedWords = try container.decodeIfPresent([String].self, forKey: .practicedWords) ?? []
        grammar = try container.decodeIfPresent(GrammarPoint.self, forKey: .grammar)
        practicedGrammar = try container.decodeIfPresent([String].self, forKey: .practicedGrammar) ?? []
    }
}

/// A grammar pattern こと pointed out, e.g. 〜ちゃう (casual 〜てしまう).
nonisolated struct GrammarPoint: Codable, Hashable, Identifiable {
    struct Example: Codable, Hashable {
        let japanese: String
        let english: String
    }

    var id: String { pattern }
    /// As it's usually written, with 〜 for the part it attaches to.
    let pattern: String
    let meaning: String
    /// The textbook (Genki) form this is a casual version of, if any.
    let base: String?
    /// How and when it's used, and the casual nuance.
    let note: String
    let examples: [Example]
}

/// An English translation of a bot message plus a phrase-by-phrase breakdown.
nonisolated struct MessageExplanation: Codable, Hashable {
    struct Part: Codable, Hashable {
        /// A chunk of the original Japanese.
        let phrase: String
        /// What it means and how it works, in English.
        let explanation: String
    }

    /// One chunk of the sentence and the job it does, for the color-coded structure view.
    struct Chunk: Codable, Hashable {
        enum Role: String, Codable, CaseIterable {
            case topic, subject, object, time, place, target, verb, description, ending, connector, other

            var label: String {
                switch self {
                case .topic: "Topic (は)"
                case .subject: "Subject (が)"
                case .object: "Object (を)"
                case .time: "Time"
                case .place: "Place / means (で)"
                case .target: "Target (に・へ・と)"
                case .verb: "Verb / predicate"
                case .description: "Describing word"
                case .ending: "Sentence ending"
                case .connector: "Connector"
                case .other: "Other"
                }
            }
        }

        let text: String
        let role: Role
    }

    let translation: String
    let breakdown: [Part]
    /// Missing in explanations saved before the structure view existed; those are fetched again.
    let structure: [Chunk]?

    init(translation: String, breakdown: [Part], structure: [Chunk]? = nil) {
        self.translation = translation
        self.breakdown = breakdown
        self.structure = structure
    }

    /// The model occasionally leaves the translation empty; such a result is fetched again.
    var isComplete: Bool {
        !translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && structure != nil
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
    /// The grammar point the mistake is about, e.g. "は vs が" or "て-form", for the mistake log.
    var grammarPoint: String? = nil

    enum CodingKeys: String, CodingKey {
        case original, suggested, type, explanation
        case grammarPoint = "grammar_point"
    }
}

nonisolated struct VocabItem: Codable, Hashable, Identifiable {
    var id: String { word }
    let word: String
    let reading: String
    let meaning: String
}
