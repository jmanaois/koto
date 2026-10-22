import Foundation

/// Anything that can produce the bot's next reply.
/// FakeChatService is used for now; a Claude-backed service will replace it later.
protocol ChatService {
    func reply(to history: [ChatMessage]) async throws -> BotResponse
}
