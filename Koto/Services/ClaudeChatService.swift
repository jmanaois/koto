import Foundation

/// こと backed by the Claude API.
///
/// Koto is a personal app, so it calls the API directly with a key read from
/// Secrets.plist (git-ignored, see Secrets.example.plist). An app shared with
/// other people would need a small server to keep the key off their phones.
struct ClaudeChatService: ChatService {
    static let model = "claude-haiku-5-5"
    /// How many recent messages to send as context.
    static let historyLimit = 40

    enum ServiceError: LocalizedError {
        case missingAPIKey
        case http(status: Int, message: String)
        case refused
        case truncated
        case unreadableResponse
        case emptyTranslation
        case emptyReply

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                "No API key yet. Paste your Anthropic API key into Koto/Secrets.plist and rebuild."
            case .http(let status, let message):
                "API error \(status): \(message)"
            case .refused:
                "The model declined to answer that message."
            case .truncated:
                "The reply was cut off. Try again."
            case .unreadableResponse:
                "Couldn't read the reply from the API."
            case .emptyTranslation:
                "The translation came back empty. Try again."
            case .emptyReply:
                "The reply came back empty. Try sending again."
            }
        }
    }

    func reply(
        to history: [ChatMessage], practiceWords: [VocabItem], mode: ChatMode, strictness: CorrectionStrictness
    ) async throws -> BotResponse {
        // Like translations, the model now and then sends "reply": "". Ask once more before giving up.
        let body = Self.body(history: history, practiceWords: practiceWords, mode: mode, strictness: strictness)
        for _ in 0..<2 {
            let response: BotResponse = try await send(body)
            if !response.reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return response }
        }
        throw ServiceError.emptyReply
    }

    func explain(_ text: String, context: [ChatMessage]) async throws -> MessageExplanation {
        let earlier = context.map { ($0.sender == .user ? "Learner: " : "Partner: ") + $0.text }
        let prompt = "<earlier_messages>\n\(earlier.joined(separator: "\n"))\n</earlier_messages>\n\n"
            + "<message>\n\(text)\n</message>"
        let body: [String: Any] = [
            "model": Self.model,
            "max_tokens": 4000,
            "system": [["type": "text", "text": KotoPrompt.explainSystem]],
            "messages": [["role": "user", "content": [["type": "text", "text": prompt]]]],
            "output_config": [
                "effort": "low",
                "format": ["type": "json_schema", "schema": KotoPrompt.explanationSchema],
            ],
        ]
        // The schema can't require a non-empty string, and now and then the model sends
        // "translation": "". Ask once more before giving up.
        for _ in 0..<2 {
            let explanation: MessageExplanation = try await send(body)
            if explanation.isComplete { return explanation }
        }
        throw ServiceError.emptyTranslation
    }

    /// Sends a Messages API request and decodes the JSON the model wrote.
    private func send<Output: Decodable>(_ body: [String: Any]) async throws -> Output {
        guard let apiKey = Self.apiKey() else { throw ServiceError.missingAPIKey }

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2026-10-21", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw ServiceError.http(status: status, message: apiError?.error.message ?? "unknown error")
        }

        let message = try JSONDecoder().decode(APIMessage.self, from: data)
        switch message.stopReason {
        case "refusal": throw ServiceError.refused
        case "max_tokens": throw ServiceError.truncated
        default: break
        }
        // With thinking on, the content can start with thinking blocks; the JSON is in the text block.
        guard let text = message.content.first(where: { $0.type == "text" })?.text,
              let output = try? JSONDecoder().decode(Output.self, from: Data(text.utf8))
        else { throw ServiceError.unreadableResponse }
        return output
    }

    // MARK: - Request

    private static func body(
        history: [ChatMessage], practiceWords: [VocabItem], mode: ChatMode, strictness: CorrectionStrictness
    ) -> [String: Any] {
        var messages = apiMessages(from: history)
        if !practiceWords.isEmpty, var last = messages.last, last["role"] as? String == "user" {
            // Practice words ride along with the newest user turn only, so earlier turns
            // stay identical between requests and the cached prefix keeps matching.
            var content = last["content"] as? [[String: Any]] ?? []
            content.append(["type": "text", "text": KotoPrompt.practiceWordsBlock(practiceWords)])
            last["content"] = content
            messages[messages.count - 1] = last
        }

        return [
            "model": model,
            "max_tokens": 4000,
            "system": [["type": "text", "text": KotoPrompt.system(for: mode, strictness: strictness)]],
            "messages": messages,
            // Caches the system prompt and conversation so far for the next message.
            "cache_control": ["type": "ephemeral"],
            "output_config": [
                // Casual chat doesn't need much thinking.
                "effort": "low",
                "format": ["type": "json_schema", "schema": KotoPrompt.outputSchema],
            ],
        ]
    }

    /// Recent chat as API messages: must start with the user, and same-sender
    /// messages in a row are merged into one turn. Group-chat messages keep their
    /// "名前：" prefix, matching the format the model writes them in.
    private static func apiMessages(from history: [ChatMessage]) -> [[String: Any]] {
        var turns: [(role: String, texts: [String])] = []
        for message in history.suffix(historyLimit) {
            let role = message.sender == .user ? "user" : "assistant"
            let text = message.speaker.map { "\($0)：\(message.text)" } ?? message.text
            if turns.isEmpty, role == "assistant" { continue }
            if turns.last?.role == role {
                turns[turns.count - 1].texts.append(text)
            } else {
                turns.append((role, [text]))
            }
        }
        return turns.map { turn in
            ["role": turn.role, "content": [["type": "text", "text": turn.texts.joined(separator: "\n")]]]
        }
    }

    private static func apiKey() -> String? {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let secrets = NSDictionary(contentsOf: url),
              let key = secrets["AnthropicAPIKey"] as? String,
              !key.isEmpty, key != "PASTE_YOUR_KEY_HERE"
        else { return nil }
        return key.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Response

    private struct APIMessage: Decodable {
        struct Block: Decodable {
            let type: String
            let text: String?
        }

        let content: [Block]
        let stopReason: String?

        enum CodingKeys: String, CodingKey {
            case content
            case stopReason = "stop_reason"
        }
    }

    private struct APIErrorResponse: Decodable {
        struct Detail: Decodable {
            let message: String
        }

        let error: Detail
    }
}
