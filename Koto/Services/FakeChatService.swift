import Foundation

/// A scripted stand-in for the real bot, for previews and testing the UI without API calls.
/// It recognizes a few common learner phrases and mistakes; everything else gets a
/// generic casual reaction.
struct FakeChatService: ChatService {
    func reply(to history: [ChatMessage], practiceWords: [VocabItem], mode: ChatMode) async throws -> BotResponse {
        // Pretend to think, like a real network call would.
        try await Task.sleep(for: .milliseconds(Int.random(in: 700...1400)))

        let text = history.last(where: { $0.sender == .user })?.text ?? ""
        let (reply, vocab) = Self.reaction(to: text)
        let practiced = practiceWords.map(\.word).filter { text.contains($0) }
        return BotResponse(reply: reply, corrections: Self.corrections(for: text), newVocab: vocab, practicedWords: practiced)
    }

    func explain(_ text: String, context: [ChatMessage]) async throws -> MessageExplanation {
        try await Task.sleep(for: .milliseconds(600))
        return MessageExplanation(
            translation: "(Sample translation; the real one comes from Claude.)",
            breakdown: [MessageExplanation.Part(phrase: text, explanation: "Sample explanation.")]
        )
    }

    // MARK: - Corrections

    private struct Rule {
        let match: String
        let suggested: String?
        let type: Correction.Kind
        let explanation: String
    }

    private static let rules: [Rule] = [
        Rule(match: "私わ", suggested: "私は", type: .grammar,
             explanation: "The topic particle is written は even though it's pronounced \"wa\"."),
        Rule(match: "僕わ", suggested: "僕は", type: .grammar,
             explanation: "The topic particle is written は even though it's pronounced \"wa\"."),
        Rule(match: "ありがとうございます", suggested: "ありがと！", type: .register,
             explanation: "ありがとうございます is polite. With friends, ありがとう or just ありがと is normal."),
        Rule(match: "わかりました", suggested: "わかった", type: .register,
             explanation: "わかりました is polite. With friends, use the plain past わかった (or りょ / りょうかい in texts)."),
        Rule(match: "そうですか", suggested: "そうなんだ", type: .register,
             explanation: "そうですか can sound distant in casual chat. そうなんだ shows you're interested."),
        Rule(match: "元気ですか", suggested: "元気？", type: .register,
             explanation: "Casual questions usually drop ですか and just use rising intonation (or a ？ in text)."),
        Rule(match: "すみません", suggested: "ごめん", type: .register,
             explanation: "With friends, ごめん (or ごめんね) is the usual way to apologize."),
        Rule(match: "こんにちは", suggested: "やっほー", type: .naturalness,
             explanation: "Friends rarely say こんにちは to each other. Try やっほー, おつ, or just jump into what you want to say."),
        Rule(match: "あなた", suggested: nil, type: .naturalness,
             explanation: "あなた can sound distant or even rude. Use the person's name, or leave \"you\" out entirely."),
    ]

    private static func corrections(for text: String) -> [Correction] {
        var results = rules
            .filter { text.contains($0.match) }
            .map { Correction(original: $0.match, suggested: $0.suggested, type: $0.type, explanation: $0.explanation) }

        // Generic note for polite forms that no specific rule covered.
        let politeEndings = ["です", "でした", "ます", "ました", "ません", "ましょう"]
        let coveredRegister = results.contains { $0.type == .register }
        if !coveredRegister, politeEndings.contains(where: text.contains) {
            results.append(Correction(
                original: text,
                suggested: nil,
                type: .register,
                explanation: "This uses polite です/ます forms. It's correct, but with a friend it sounds distant. Try the plain form, e.g. 行きます → 行く, 行きました → 行った, 学生です → 学生だよ."
            ))
        }

        if text.hasPrefix("私は") {
            results.append(Correction(
                original: "私は",
                suggested: nil,
                type: .naturalness,
                explanation: "Japanese usually drops 私は when it's obvious you're talking about yourself."
            ))
        }
        return results
    }

    // MARK: - Replies

    private static let keywordReplies: [(keywords: [String], reply: String, vocab: [VocabItem])] = [
        (["こんにち", "やっほ", "おはよ", "こんばん"], "やっほー！今日なにしてた？",
         [VocabItem(word: "やっほー", reading: "やっほー", meaning: "hey! / hiya (casual greeting)")]),
        (["映画"], "え、いいな〜！何見たの？",
         [VocabItem(word: "いいな", reading: "いいな", meaning: "lucky you / I'm jealous / sounds nice")]),
        (["ありがと"], "いえいえ〜😊",
         [VocabItem(word: "いえいえ", reading: "いえいえ", meaning: "no problem / don't mention it")]),
        (["元気"], "元気だよ！そっちは？",
         [VocabItem(word: "そっち", reading: "そっち", meaning: "you / your side (casual)")]),
        (["食べ", "ご飯", "ごはん"], "おいしそう！どこで食べたの？",
         [VocabItem(word: "おいしそう", reading: "おいしそう", meaning: "looks delicious")]),
        (["学生", "学校", "大学"], "そうなんだ！勉強大変？",
         [VocabItem(word: "大変", reading: "たいへん", meaning: "tough / hard / a lot of work")]),
    ]

    private static let genericReplies: [(reply: String, vocab: [VocabItem])] = [
        ("へー、そうなんだ！", [VocabItem(word: "へー", reading: "へー", meaning: "huh / oh really (showing interest)")]),
        ("マジで？笑", [VocabItem(word: "マジで", reading: "まじで", meaning: "seriously? / for real")]),
        ("それな〜", [VocabItem(word: "それな", reading: "それな", meaning: "right?! / exactly (internet slang)")]),
        ("わかる〜", [VocabItem(word: "わかる", reading: "わかる", meaning: "I get it / same / relatable")]),
        ("えー、すごい！", [VocabItem(word: "すごい", reading: "すごい", meaning: "amazing / wow")]),
    ]

    private static func reaction(to text: String) -> (String, [VocabItem]) {
        if let match = keywordReplies.first(where: { entry in entry.keywords.contains { text.contains($0) } }) {
            return (match.reply, match.vocab)
        }
        let pick = genericReplies.randomElement()!
        return (pick.reply, pick.vocab)
    }
}
