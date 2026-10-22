import Foundation
import SQLite3

/// One JMdict entry.
nonisolated struct DictionaryEntry: Identifiable, Hashable {
    let id: Int
    let headword: String
    let reading: String
    /// JMdict part-of-speech codes, e.g. "v1", "adj-i", "n".
    let partsOfSpeech: [String]
    /// JMdict usage notes, e.g. "col" (colloquial), "sl" (slang).
    let tags: [String]
    let meanings: [String]
    /// Whether the spelling that was looked up is a common one for this entry.
    let isCommonForm: Bool

    var vocabItem: VocabItem {
        VocabItem(word: headword, reading: reading, meaning: meanings.first ?? "")
    }
}

/// The dictionary entries found for text the user tapped.
nonisolated struct LookupResult {
    /// The part of the message that matched, e.g. 食べました.
    let matched: String
    let entries: [DictionaryEntry]
}

/// Read-only access to the bundled JMdict database (built by tools/build_dictionary.py).
final class JapaneseDictionary {
    static let shared = JapaneseDictionary()

    private var db: OpaquePointer?

    private init() {
        guard let url = Bundle.main.url(forResource: "jmdict", withExtension: "sqlite"),
              sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK
        else {
            db = nil
            return
        }
    }

    /// Finds the longest dictionary word at the start of `text`, undoing common
    /// conjugations along the way (食べました → 食べる, 高かった → 高い).
    func lookup(_ text: String, maxLength: Int = 12, limit: Int = 3) -> LookupResult? {
        let characters = Array(text.prefix(maxLength))
        for length in stride(from: characters.count, through: 1, by: -1) {
            let candidate = String(characters[..<length])
            // The text as written, then possible dictionary forms. Deinflector steps
            // without a part of speech are only stepping stones, not answers.
            let forms = [(candidate, nil)] + Deinflector.candidates(for: candidate).filter { $0.1 != nil }

            var found: [DictionaryEntry] = []
            for (form, requiredPOS) in forms {
                for entry in entries(for: form) where !found.contains(where: { $0.id == entry.id }) {
                    if let requiredPOS, !entry.partsOfSpeech.contains(where: { $0.hasPrefix(requiredPOS) }) {
                        continue
                    }
                    found.append(entry)
                }
            }
            if !found.isEmpty {
                // Prefer entries reached through a common spelling: 行って → 行く, not the rare 行る (やる).
                // The sort is stable, so ties keep the order above.
                let ranked = found.enumerated()
                    .sorted { ($0.element.isCommonForm ? 0 : 1, $0.offset) < ($1.element.isCommonForm ? 0 : 1, $1.offset) }
                    .map(\.element)
                return LookupResult(matched: candidate, entries: Array(ranked.prefix(limit)))
            }
        }
        return nil
    }

    func entries(for form: String, limit: Int = 5) -> [DictionaryEntry] {
        guard let db else { return [] }
        let sql = """
            SELECT e.id, e.headword, e.reading, e.pos, e.tags, e.meanings, f.common
            FROM forms f JOIN entries e ON e.id = f.entry_id
            WHERE f.form = ?
            ORDER BY f.common DESC, e.common DESC, e.id
            LIMIT ?
            """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(statement, 1, form, -1, sqliteTransient)
        sqlite3_bind_int(statement, 2, Int32(limit))

        var results: [DictionaryEntry] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            func text(_ column: Int32) -> String {
                sqlite3_column_text(statement, column).map { String(cString: $0) } ?? ""
            }
            results.append(DictionaryEntry(
                id: Int(sqlite3_column_int64(statement, 0)),
                headword: text(1),
                reading: text(2),
                partsOfSpeech: text(3).split(separator: " ").map(String.init),
                tags: text(4).split(separator: " ").map(String.init),
                meanings: text(5).split(separator: "\n").map(String.init),
                isCommonForm: sqlite3_column_int(statement, 6) != 0
            ))
        }
        return results
    }
}

/// Tells SQLite to copy bound strings (Swift doesn't import the SQLITE_TRANSIENT macro).
private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// Turns conjugated words back into dictionary forms so they can be looked up.
/// Each candidate comes with the part of speech the dictionary entry must have,
/// which filters out false matches. Covers the common forms, not every one.
nonisolated enum Deinflector {
    private struct Rule {
        let from: String
        let to: String
        /// Required JMdict part-of-speech prefix, or nil for an intermediate step.
        let pos: String?
    }

    static func candidates(for word: String) -> [(String, String?)] {
        var results: [(String, String?)] = []
        var seen: Set<String> = []
        var frontier = [word]
        // Up to three steps handles chains like 食べたくなかった → 食べたくない → 食べたい → 食べる.
        for _ in 0..<3 {
            var next: [String] = []
            for form in frontier {
                for rule in rules where form.hasSuffix(rule.from) {
                    let result = String(form.dropLast(rule.from.count)) + rule.to
                    guard !result.isEmpty, result != form else { continue }
                    let key = result + "|" + (rule.pos ?? "")
                    guard seen.insert(key).inserted else { continue }
                    results.append((result, rule.pos))
                    next.append(result)
                }
            }
            frontier = next
        }
        return results
    }

    private static let rules: [Rule] = {
        var rules: [Rule] = []
        func add(_ froms: [String], _ to: String, _ pos: String?) {
            rules += froms.map { Rule(from: $0, to: to, pos: pos) }
        }

        // 行く is the only verb whose て/た form is って/った with a く ending. Spelled out with
        // its stem so it can't turn other verbs into く verbs (あった → 開く instead of ある),
        // and listed first so 行って prefers 行く over 行う.
        add(["行って", "行った"], "行く", "v5k")
        add(["いって", "いった"], "いく", "v5k")

        // Godan verbs: (dictionary ending, i-row, a-row, e-row, o-row, te, ta, pos)
        let godan: [(String, String, String, String, String, String, String, String)] = [
            ("く", "き", "か", "け", "こ", "いて", "いた", "v5k"),
            ("ぐ", "ぎ", "が", "げ", "ご", "いで", "いだ", "v5g"),
            ("す", "し", "さ", "せ", "そ", "して", "した", "v5s"),
            ("つ", "ち", "た", "て", "と", "って", "った", "v5t"),
            ("ぬ", "に", "な", "ね", "の", "んで", "んだ", "v5n"),
            ("ぶ", "び", "ば", "べ", "ぼ", "んで", "んだ", "v5b"),
            ("む", "み", "ま", "め", "も", "んで", "んだ", "v5m"),
            ("る", "り", "ら", "れ", "ろ", "って", "った", "v5r"),
            ("う", "い", "わ", "え", "お", "って", "った", "v5u"),
        ]
        for (u, i, a, e, o, te, ta, pos) in godan {
            add(["ます", "ました", "ません", "ませんでした", "ましょう", "たい", "ながら", "なさい", ""].map { i + $0 }, u, pos)
            add(["ない", "なかった", "なくて", "ず", "れる", "せる"].map { a + $0 }, u, pos)
            add([e + "る", e + "ば", o + "う", te, ta], u, pos)
        }

        // Ichidan verbs (食べる, 見る)
        add(["ます", "ました", "ません", "ませんでした", "ましょう", "た", "て", "ない", "なかった", "なくて",
             "たい", "よう", "られる", "させる", "れば", "ず", "ながら", "なさい", ""], "る", "v1")

        // する verbs: 勉強して → 勉強 (noun that takes する), and する itself
        let suru = ["する", "します", "しました", "しません", "して", "した", "しない", "しなかった",
                    "したい", "しよう", "される", "させる", "すれば", "しろ", "せず"]
        add(suru, "", "vs")
        add(suru, "する", "vs-i")

        // 来る
        let kuru = ["きます", "きました", "きません", "きて", "きた", "こない", "こなかった", "きたい", "こよう", "くれば", "こられる"]
        add(kuru, "くる", "vk")
        add(kuru.map { "来" + $0.dropFirst() }, "来る", "vk")

        // い-adjectives, including いい
        add(["かった", "くない", "くなかった", "くて", "く", "ければ", "さ", "そう", "すぎる"], "い", "adj-i")
        add(["よかった", "よくない", "よくなかった", "よくて", "よければ"], "いい", "adj-ix")

        // Casual contractions that reduce to another form, resolved by a later step.
        add(["てる", "ている", "てた", "てます", "ちゃう", "ちゃった"], "て", nil)
        add(["でる", "でいる", "でた", "でます", "じゃう", "じゃった"], "で", nil)
        add(["たら", "たり"], "た", nil)
        add(["だら", "だり"], "だ", nil)
        add(["ないで", "なくちゃ"], "ない", nil)
        return rules
    }()
}
