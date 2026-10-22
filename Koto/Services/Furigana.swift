import Foundation

/// One unit of message text for layout: a word with readings over its kanji,
/// the text between words, or a line break.
nonisolated struct FuriganaToken: Identifiable {
    struct Run {
        let text: String
        /// Hiragana reading shown above `text`; only set for kanji.
        let reading: String?
    }

    /// UTF-16 offset of the token in the message, unique per token.
    let id: Int
    var runs: [Run]
    /// Text to look up when the token is tapped: from this word to the next
    /// non-Japanese character, so conjugations can match. nil if not tappable.
    let lookupText: String?
    var isLineBreak = false
}

/// Splits text into words with furigana, using the system Japanese tokenizer
/// for both word boundaries and readings.
nonisolated enum Furigana {
    static func tokens(for text: String) -> [FuriganaToken] {
        let string = text as CFString
        guard let tokenizer = CFStringTokenizerCreate(
            nil, string, CFRange(location: 0, length: CFStringGetLength(string)),
            kCFStringTokenizerUnitWordBoundary, Locale(identifier: "ja") as CFLocale
        ) else { return plainTokens(text, from: 0) }

        let utf16 = text.utf16
        var tokens: [FuriganaToken] = []
        var cursor = 0
        while !CFStringTokenizerAdvanceToNextToken(tokenizer).isEmpty {
            let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            if range.location > cursor {
                tokens += plainTokens(substring(text, cursor, range.location), from: cursor)
            }
            let word = substring(text, range.location, range.location + range.length)
            cursor = range.location + range.length
            // The tokenizer returns newlines as words; turn them into line breaks.
            if word.contains("\n") {
                tokens += plainTokens(word, from: range.location)
                continue
            }
            let transcription = CFStringTokenizerCopyCurrentTokenAttribute(
                tokenizer, kCFStringTokenizerAttributeLatinTranscription
            ) as? String
            let end = range.location + range.length
            let nextCharacter = end < utf16.count ? substring(text, end, end + 1).first : nil
            let reading = readingOverride(for: word, next: nextCharacter) ?? hiraganaReading(transcription)
            tokens.append(FuriganaToken(
                id: range.location,
                runs: runs(for: word, reading: reading),
                lookupText: lookupText(in: text, at: range.location)
            ))
        }
        if cursor < utf16.count {
            tokens += plainTokens(substring(text, cursor, utf16.count), from: cursor)
        }
        return keepingPunctuationAttached(tokens)
    }

    /// Japanese text never starts a line with closing punctuation, so glue it onto the
    /// word before it: then 「みんな。」 wraps as a unit instead of leaving 「。」 alone.
    private static func keepingPunctuationAttached(_ tokens: [FuriganaToken]) -> [FuriganaToken] {
        let closing = Set("、。，．！？!?）」』〜ー…・ｗw")
        var result: [FuriganaToken] = []
        for token in tokens {
            let isClosingPunctuation = token.lookupText == nil && !token.isLineBreak
                && token.runs.allSatisfy { $0.reading == nil && $0.text.allSatisfy(closing.contains) }
            if isClosingPunctuation, let last = result.last, !last.isLineBreak {
                result[result.count - 1].runs += token.runs
            } else {
                result.append(token)
            }
        }
        return result
    }

    static func isJapanese(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { scalar in
            switch scalar.value {
            case 0x3041...0x309F, 0x30A1...0x30FA, 0x30FC...0x30FF, 0x3400...0x4DBF, 0x4E00...0x9FFF, 0x3005:
                true
            default:
                false
            }
        }
    }

    /// Whether `token` is a form of one of `knownWords` (dictionary forms like 食べる, 大変, 行く).
    /// The kanji must match exactly and the token must start with the word's stem, so
    /// 食べ(ました) and 行き(ました) match 食べる and 行く, but 食事 and 映画館 don't match 食べる and 映画.
    static func isForm(of knownWords: Set<String>, _ token: FuriganaToken) -> Bool {
        let text = token.runs.map(\.text).joined()
        guard !knownWords.isEmpty, text.contains(where: isKanji) else { return false }
        let core = kanjiCore(text)
        return knownWords.contains { word in
            word.contains(where: isKanji) && kanjiCore(word) == core && text.hasPrefix(stem(of: word))
        }
    }

    /// The text up to and including its last kanji: 食べる → 食, 大変 → 大変.
    private static func kanjiCore(_ text: String) -> String {
        guard let last = text.lastIndex(where: isKanji) else { return "" }
        return String(text[...last])
    }

    /// The part of a dictionary form that stays the same when it conjugates: the word minus a
    /// trailing kana ending. 食べる → 食べ, 行く → 行, 面白い → 面白, 大変 → 大変.
    private static func stem(of word: String) -> String {
        let core = kanjiCore(word)
        let rest = word.dropFirst(core.count)
        return core + rest.dropLast()
    }

    private static func isKanji(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { scalar in
            switch scalar.value {
            case 0x3400...0x4DBF, 0x4E00...0x9FFF, 0x3005: true
            default: false
            }
        }
    }

    /// Text between words (spaces, punctuation), with newlines as line breaks.
    private static func plainTokens(_ text: String, from offset: Int) -> [FuriganaToken] {
        var tokens: [FuriganaToken] = []
        var position = offset
        for (index, line) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            if index > 0 {
                tokens.append(FuriganaToken(id: position, runs: [], lookupText: nil, isLineBreak: true))
                position += 1
            }
            if !line.isEmpty {
                tokens.append(FuriganaToken(id: position, runs: [.init(text: String(line), reading: nil)], lookupText: nil))
                position += line.utf16.count
            }
        }
        return tokens
    }

    private static func lookupText(in text: String, at offset: Int) -> String? {
        let start = String.Index(utf16Offset: offset, in: text)
        let run = text[start...].prefix(while: isJapanese)
        return run.isEmpty ? nil : String(run)
    }

    /// Splits a word into kanji and kana runs and matches the reading to them,
    /// so 食べ物 (たべもの) becomes 食(た) べ 物(もの).
    private static func runs(for word: String, reading: String?) -> [FuriganaToken.Run] {
        guard word.contains(where: isKanji), let reading else {
            return [.init(text: word, reading: nil)]
        }

        var groups: [(text: String, isKanji: Bool)] = []
        for character in word {
            let kanji = isKanji(character)
            if let last = groups.last, last.isKanji == kanji {
                groups[groups.count - 1].text.append(character)
            } else {
                groups.append((String(character), kanji))
            }
        }

        let pattern = "^" + groups.map { group in
            group.isKanji ? "(.+?)" : NSRegularExpression.escapedPattern(for: toHiragana(group.text))
        }.joined() + "$"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: reading, range: NSRange(reading.startIndex..., in: reading))
        else {
            // Couldn't line the reading up with the kana; show it over the whole word.
            return [.init(text: word, reading: reading)]
        }

        var captureGroup = 1
        return groups.map { group in
            guard group.isKanji else { return .init(text: group.text, reading: nil) }
            defer { captureGroup += 1 }
            let range = Range(match.range(at: captureGroup), in: reading)
            return .init(text: group.text, reading: range.map { String(reading[$0]) })
        }
    }

    /// Fixes for common words the tokenizer reads differently from everyday speech.
    private static func readingOverride(for word: String, next: Character?) -> String? {
        switch word {
        case "日本":
            return "にほん"
        case "私":
            return "わたし"
        case "何":
            // なん before counters and で/の/だ/と/て (何で, 何の, 何時); なに otherwise (何する, 何見た).
            let nanFollowers: Set<Character> = ["で", "の", "だ", "と", "て", "時", "回", "人", "歳", "個", "本", "枚", "度", "年", "月", "日", "分"]
            return next.map(nanFollowers.contains) == true ? "なん" : "なに"
        default:
            return nil
        }
    }

    /// The tokenizer gives romaji; convert it to hiragana and reject anything that didn't convert cleanly.
    private static func hiraganaReading(_ transcription: String?) -> String? {
        guard let transcription else { return nil }
        let hiragana = NSMutableString(string: transcription)
        CFStringTransform(hiragana, nil, kCFStringTransformLatinHiragana, false)
        let result = hiragana as String
        let isClean = result.unicodeScalars.allSatisfy { (0x3041...0x309F).contains($0.value) || $0.value == 0x30FC }
        return isClean && !result.isEmpty ? result : nil
    }

    private static func toHiragana(_ text: String) -> String {
        text.applyingTransform(.hiraganaToKatakana, reverse: true) ?? text
    }

    private static func substring(_ text: String, _ start: Int, _ end: Int) -> String {
        let from = String.Index(utf16Offset: start, in: text)
        let to = String.Index(utf16Offset: end, in: text)
        return String(text[from..<to])
    }
}
