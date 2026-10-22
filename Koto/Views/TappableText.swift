import Foundation

/// Turns message text into an AttributedString where each Japanese word is a link,
/// so any word in a bubble can be tapped to look it up.
enum TappableText {
    private static let scheme = "koto-lookup"

    static func attributed(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        for range in wordRanges(in: text) where text[range].contains(where: isJapanese) {
            let offset = range.lowerBound.utf16Offset(in: text)
            guard let attributedRange = Range(range, in: result) else { continue }
            result[attributedRange].link = URL(string: "\(scheme)://word?offset=\(offset)")
        }
        return result
    }

    /// The text to look up for a tapped link: from the tapped word to the next
    /// non-Japanese character, so conjugations and longer expressions can match.
    static func lookupText(in text: String, for url: URL) -> String? {
        guard url.scheme == scheme,
              let value = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                  .queryItems?.first(where: { $0.name == "offset" })?.value,
              let offset = Int(value),
              offset < text.utf16.count
        else { return nil }
        let start = String.Index(utf16Offset: offset, in: text)
        let run = text[start...].prefix(while: isJapanese)
        return run.isEmpty ? nil : String(run)
    }

    /// Word boundaries from the system's Japanese tokenizer.
    private static func wordRanges(in text: String) -> [Range<String.Index>] {
        let string = text as CFString
        guard let tokenizer = CFStringTokenizerCreate(
            nil, string, CFRange(location: 0, length: CFStringGetLength(string)),
            kCFStringTokenizerUnitWordBoundary, Locale(identifier: "ja") as CFLocale
        ) else { return [] }

        var ranges: [Range<String.Index>] = []
        while !CFStringTokenizerAdvanceToNextToken(tokenizer).isEmpty {
            let token = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            if let range = Range(NSRange(location: token.location, length: token.length), in: text) {
                ranges.append(range)
            }
        }
        return ranges
    }

    /// Hiragana, katakana (including ー) and kanji (including 々).
    private static func isJapanese(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { scalar in
            switch scalar.value {
            case 0x3041...0x309F, 0x30A1...0x30FA, 0x30FC...0x30FF, 0x3400...0x4DBF, 0x4E00...0x9FFF, 0x3005:
                true
            default:
                false
            }
        }
    }
}
