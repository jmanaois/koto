import Foundation

/// Anything that can produce the bot's next reply.
/// ClaudeChatService is the real bot; FakeChatService is a scripted stand-in for previews.
protocol ChatService {
    /// - Parameter practiceWords: words from the user's deck that are due, for the bot to work in.
    func reply(to history: [ChatMessage], practiceWords: [VocabItem]) async throws -> BotResponse

    /// An English translation and breakdown of one bot message.
    /// - Parameter context: a few messages before it, to translate in context.
    func explain(_ text: String, context: [ChatMessage]) async throws -> MessageExplanation
}
