import Foundation

/// User preferences, stored in UserDefaults (read with @AppStorage in views).
nonisolated enum AppSettings {
    static let strictnessKey = "correctionStrictness"
    static let furiganaKey = "showFurigana"

    static var strictness: CorrectionStrictness {
        UserDefaults.standard.string(forKey: strictnessKey).flatMap(CorrectionStrictness.init(rawValue:)) ?? .balanced
    }
}

/// How picky こと is about the user's messages.
nonisolated enum CorrectionStrictness: String, CaseIterable, Identifiable {
    case gentle
    case balanced
    case strict

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gentle: "Gentle"
        case .balanced: "Balanced"
        case .strict: "Strict"
        }
    }

    var summary: String {
        switch self {
        case .gentle: "Only real mistakes. Keeps the conversation flowing."
        case .balanced: "Mistakes plus clearly unnatural or wrong-politeness phrasing."
        case .strict: "Everything a native speaker would say differently, including every です/ます with a friend."
        }
    }

    /// The correction rules for the system prompt.
    var promptRule: String {
        let base: String
        switch self {
        case .gentle:
            base = """
            Be gentle: only correct real grammar mistakes and wording a native speaker would misunderstand or \
            find very odd. Skip small naturalness and politeness issues unless they would really stand out. \
            If the message is understandable and roughly right, return no corrections. At most two, most \
            important first.
            """
        case .balanced:
            base = """
            Don't nitpick. If the message is fine for this conversation, return no corrections. If the whole \
            message is at the wrong politeness level, one register correction for the whole message is enough. \
            At most three, most important first.
            """
        case .strict:
            base = """
            Be thorough: correct every grammar, naturalness and register issue you notice, including small ones, \
            so the user learns exactly how a native speaker would say it. Always flag politeness that doesn't \
            fit this conversation, even a single です or ます with a friend. At most five, most important first.
            """
        }
        return base + "\nAlways ignore punctuation, kanji-vs-kana choices, and anything that is just an input-method quirk."
    }
}
