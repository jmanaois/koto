import Foundation

/// Anything that can produce the bot's next reply.
/// ClaudeChatService is the real bot; FakeChatService is a scripted stand-in for previews.
protocol ChatService {
    /// - Parameters:
    ///   - study: due words and grammar for the bot to work in, and grammar the user often gets wrong.
    ///   - mode: who the user is chatting with, which sets the persona and politeness level.
    ///   - strictness: how picky the corrections should be.
    func reply(
        to history: [ChatMessage], study: StudyContext, mode: ChatMode, strictness: CorrectionStrictness
    ) async throws -> BotResponse

    /// An English translation and breakdown of one bot message.
    /// - Parameter context: a few messages before it, to translate in context.
    func explain(_ text: String, context: [ChatMessage]) async throws -> MessageExplanation

    /// Whether a typed course answer is right, for answers that don't match the expected ones exactly.
    /// - Parameters:
    ///   - expected: model answers; others can be right too.
    ///   - grammar: the grammar point the exercise practices.
    func gradeTranslation(
        _ answer: String, english: String, expected: [String], grammar: GrammarPoint
    ) async throws -> TranslationGrade
}

/// What the user is currently studying, sent along with each message.
nonisolated struct StudyContext {
    var words: [VocabItem] = []
    var grammar: [GrammarPoint] = []
    /// Grammar points the user often gets wrong, most frequent first.
    var weakPoints: [String] = []
}

/// Claude's verdict on a typed course answer.
nonisolated struct TranslationGrade: Codable {
    let correct: Bool
    /// One or two sentences: what to fix, or a note on how it differs from the model answer.
    let feedback: String
}
