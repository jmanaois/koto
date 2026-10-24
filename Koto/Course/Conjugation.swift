import Foundation

/// A verb in dictionary form, with what it needs to conjugate.
nonisolated struct Verb: Hashable, Codable {
    enum Group: String, Codable {
        /// る-verbs (ichidan): drop る.
        case ru
        /// う-verbs (godan): the last sound changes.
        case u
        /// する and Noun + する.
        case suru
        /// 来る.
        case kuru

        var label: String {
            switch self {
            case .ru: "る-verb"
            case .u: "う-verb"
            case .suru, .kuru: "irregular"
            }
        }
    }

    let kanji: String
    /// Hiragana reading of the dictionary form.
    let kana: String
    let english: String
    let group: Group

    init(_ kanji: String, _ kana: String, _ english: String, _ group: Group) {
        self.kanji = kanji
        self.kana = kana
        self.english = english
        self.group = group
    }
}

/// A verb form to conjugate into. Derived forms (potential, passive, causative…) make a new
/// る-verb, which can be conjugated again: [.passive, .past] → 食べられた.
nonisolated enum VerbForm: String, CaseIterable, Codable, Identifiable {
    case polite, negative, past, pastNegative, te
    case potential, volitional, conditional, imperative
    case passive, causative, causativePassive

    var id: String { rawValue }

    var label: String {
        switch self {
        case .polite: "ます"
        case .negative: "ない (negative)"
        case .past: "た (past)"
        case .pastNegative: "なかった (past negative)"
        case .te: "て-form"
        case .potential: "potential (can)"
        case .volitional: "volitional (let's)"
        case .conditional: "ば (if)"
        case .imperative: "imperative (command)"
        case .passive: "passive"
        case .causative: "causative (make / let)"
        case .causativePassive: "causative-passive (be made to)"
        }
    }

    /// Short name used when forms are chained, e.g. "passive + past".
    var shortLabel: String {
        switch self {
        case .polite: "ます"
        case .negative: "negative"
        case .past: "past"
        case .pastNegative: "past negative"
        case .te: "て-form"
        case .potential: "potential"
        case .volitional: "volitional"
        case .conditional: "ば"
        case .imperative: "imperative"
        case .passive: "passive"
        case .causative: "causative"
        case .causativePassive: "causative-passive"
        }
    }

    /// Makes a new る-verb that can take another form.
    var isDerived: Bool {
        switch self {
        case .potential, .passive, .causative, .causativePassive: true
        default: false
        }
    }

    /// Forms that can follow a derived form in a chain.
    static let endings: [VerbForm] = [.polite, .negative, .past, .pastNegative, .te]
    static let basics: [VerbForm] = [.polite, .negative, .past, .pastNegative, .te]
    static let advanced: [VerbForm] = [.potential, .volitional, .conditional, .imperative, .passive, .causative, .causativePassive]
}

/// Conjugates verbs, in kanji and kana, without a dictionary.
nonisolated enum Conjugator {
    struct Result: Hashable {
        let kanji: String
        let kana: String
        /// Other forms that are also right, e.g. the short causative-passive 飲まされる.
        var alternates: [String] = []
    }

    /// The verb after each form in `forms`, in order. Every form but the last must be derived.
    static func conjugate(_ verb: Verb, _ forms: [VerbForm]) -> Result {
        var current = verb
        var alternates: [String] = []
        for (index, form) in forms.enumerated() {
            let result = conjugate(current, form)
            if index == forms.count - 1 {
                return Result(kanji: result.kanji, kana: result.kana, alternates: alternates + result.alternates)
            }
            // Carry the short causative-passive through the rest of the chain.
            alternates = result.alternates.compactMap { alternate in
                guard alternate.hasSuffix("る") else { return nil }
                let derived = Verb(alternate, alternate, verb.english, .ru)
                let rest = conjugate(derived, Array(forms[(index + 1)...]))
                return rest.kana
            }
            current = Verb(result.kanji, result.kana, verb.english, .ru)
        }
        return Result(kanji: verb.kanji, kana: verb.kana)
    }

    static func conjugate(_ verb: Verb, _ form: VerbForm) -> Result {
        switch verb.group {
        case .kuru:
            let kana = kuru(form)
            // 来 covers the first kana, whichever reading it has.
            let kanji = verb.kanji.hasPrefix("来") ? "来" + kana.dropFirst() : kana
            return Result(kanji: kanji, kana: kana)
        case .suru:
            let kanjiStem = String(verb.kanji.dropLast(2))
            let kanaStem = String(verb.kana.dropLast(2))
            let ending = suru(form)
            return Result(kanji: kanjiStem + ending, kana: kanaStem + ending)
        case .ru, .u:
            let ending = verb.group == .ru ? ru(form) : u(verb, form)
            var result = Result(kanji: String(verb.kanji.dropLast()) + ending, kana: String(verb.kana.dropLast()) + ending)
            if form == .causativePassive, verb.group == .u, verb.kana.last != "す" {
                let short = row(verb.kana.last!, .a) + "される"
                result.alternates = [String(verb.kana.dropLast()) + short, String(verb.kanji.dropLast()) + short]
            }
            return result
        }
    }

    /// How the form is made for this verb, shown after answering.
    static func rule(_ verb: Verb, _ forms: [VerbForm]) -> String {
        guard let form = forms.first else { return "" }
        let first = rule(verb, form)
        guard forms.count > 1 else { return first }
        let derived = conjugate(verb, form)
        let endings = forms.dropFirst().map(ru).joined(separator: ", then ")
        return first + " Then \(derived.kanji) works like a る-verb: drop る, add \(endings)."
    }

    private static func rule(_ verb: Verb, _ form: VerbForm) -> String {
        let last = verb.kana.last.map(String.init) ?? ""
        switch verb.group {
        case .kuru:
            return "来る is irregular: \(kuru(form)) (\(form.shortLabel))."
        case .suru:
            return "する is irregular: \(suru(form)) (\(form.shortLabel))."
        case .ru:
            return "\(verb.kanji) is a る-verb: drop る, add \(ru(form))."
        case .u:
            let ending = u(verb, form)
            if (form == .te || form == .past), isIku(verb) {
                let stem = verb.kanji.dropLast()
                return "\(verb.kanji) is the one exception: \(stem)\(ending), not \(stem)\(form == .te ? "いて" : "いた")."
            }
            switch form {
            case .te, .past:
                return "\(verb.kanji) is a う-verb ending in \(last): \(last) → \(ending)."
            case .negative where last == "う", .pastNegative where last == "う":
                return "\(verb.kanji) is a う-verb ending in う: う → わ, then \(ending.dropFirst())."
            default:
                return "\(verb.kanji) is a う-verb: \(last) → \(ending)."
            }
        }
    }

    // MARK: - Endings

    private static func ru(_ form: VerbForm) -> String {
        switch form {
        case .polite: "ます"
        case .negative: "ない"
        case .past: "た"
        case .pastNegative: "なかった"
        case .te: "て"
        case .potential, .passive: "られる"
        case .volitional: "よう"
        case .conditional: "れば"
        case .imperative: "ろ"
        case .causative: "させる"
        case .causativePassive: "させられる"
        }
    }

    private static func u(_ verb: Verb, _ form: VerbForm) -> String {
        let last = verb.kana.last!
        switch form {
        case .polite: return row(last, .i) + "ます"
        case .negative: return row(last, .a) + "ない"
        case .pastNegative: return row(last, .a) + "なかった"
        case .te, .past:
            let ending: String
            if isIku(verb) {
                ending = "って"
            } else {
                switch last {
                case "う", "つ", "る": ending = "って"
                case "む", "ぶ", "ぬ": ending = "んで"
                case "く": ending = "いて"
                case "ぐ": ending = "いで"
                default: ending = "して"
                }
            }
            return form == .te ? ending : String(ending.dropLast()) + (ending.hasSuffix("で") ? "だ" : "た")
        case .potential: return row(last, .e) + "る"
        case .volitional: return row(last, .o) + "う"
        case .conditional: return row(last, .e) + "ば"
        case .imperative: return row(last, .e)
        case .passive: return row(last, .a) + "れる"
        case .causative: return row(last, .a) + "せる"
        case .causativePassive: return row(last, .a) + "せられる"
        }
    }

    private static func suru(_ form: VerbForm) -> String {
        switch form {
        case .polite: "します"
        case .negative: "しない"
        case .past: "した"
        case .pastNegative: "しなかった"
        case .te: "して"
        case .potential: "できる"
        case .volitional: "しよう"
        case .conditional: "すれば"
        case .imperative: "しろ"
        case .passive: "される"
        case .causative: "させる"
        case .causativePassive: "させられる"
        }
    }

    private static func kuru(_ form: VerbForm) -> String {
        switch form {
        case .polite: "きます"
        case .negative: "こない"
        case .past: "きた"
        case .pastNegative: "こなかった"
        case .te: "きて"
        case .potential, .passive: "こられる"
        case .volitional: "こよう"
        case .conditional: "くれば"
        case .imperative: "こい"
        case .causative: "こさせる"
        case .causativePassive: "こさせられる"
        }
    }

    private static func isIku(_ verb: Verb) -> Bool {
        verb.group == .u && (verb.kana == "いく" || verb.kanji.hasSuffix("行く"))
    }

    private enum Vowel: Int { case a, i, u, e, o }

    private static let rows: [Character: String] = [
        "う": "わいうえお", "く": "かきくけこ", "ぐ": "がぎぐげご", "す": "さしすせそ", "つ": "たちつてと",
        "ぬ": "なにぬねの", "ぶ": "ばびぶべぼ", "む": "まみむめも", "る": "らりるれろ",
    ]

    private static func row(_ kana: Character, _ vowel: Vowel) -> String {
        guard let row = rows[kana] else { return String(kana) }
        return String(Array(row)[vowel.rawValue])
    }

    // MARK: - Checking

    /// Whether `typed` is the conjugated form, in kanji or kana.
    static func matches(_ typed: String, _ result: Result) -> Bool {
        let given = normalized(typed)
        guard !given.isEmpty else { return false }
        let accepted = [result.kanji, result.kana] + result.alternates
        return accepted.contains { normalized($0) == given } || accepted.contains { Exercise.comparable($0) == Exercise.comparable(typed) }
    }

    private static func normalized(_ text: String) -> String {
        let trimmed = text.filter { !$0.isWhitespace && !"。、.,".contains($0) }
        return trimmed.applyingTransform(.hiraganaToKatakana, reverse: true) ?? trimmed
    }
}

// MARK: - Verbs

nonisolated extension Verb {
    static func named(_ kanji: String) -> Verb {
        guard let verb = pool.first(where: { $0.kanji == kanji }) else { fatalError("No verb \(kanji) in Verb.pool") }
        return verb
    }

    /// Common N5–N3 verbs, every group and every う-verb ending.
    static let pool: [Verb] = [
        Verb("食べる", "たべる", "eat", .ru),
        Verb("見る", "みる", "see, watch", .ru),
        Verb("起きる", "おきる", "get up", .ru),
        Verb("寝る", "ねる", "sleep", .ru),
        Verb("教える", "おしえる", "teach", .ru),
        Verb("開ける", "あける", "open", .ru),
        Verb("閉める", "しめる", "close", .ru),
        Verb("忘れる", "わすれる", "forget", .ru),
        Verb("着る", "きる", "wear", .ru),
        Verb("出る", "でる", "leave, go out", .ru),
        Verb("借りる", "かりる", "borrow", .ru),
        Verb("決める", "きめる", "decide", .ru),
        Verb("始める", "はじめる", "begin", .ru),
        Verb("信じる", "しんじる", "believe", .ru),
        Verb("調べる", "しらべる", "look into", .ru),
        Verb("答える", "こたえる", "answer", .ru),
        Verb("続ける", "つづける", "continue", .ru),
        Verb("捨てる", "すてる", "throw away", .ru),
        Verb("降りる", "おりる", "get off", .ru),
        Verb("覚える", "おぼえる", "memorize", .ru),
        Verb("飲む", "のむ", "drink", .u),
        Verb("読む", "よむ", "read", .u),
        Verb("休む", "やすむ", "rest", .u),
        Verb("住む", "すむ", "live", .u),
        Verb("書く", "かく", "write", .u),
        Verb("聞く", "きく", "listen, ask", .u),
        Verb("歩く", "あるく", "walk", .u),
        Verb("働く", "はたらく", "work", .u),
        Verb("行く", "いく", "go", .u),
        Verb("泳ぐ", "およぐ", "swim", .u),
        Verb("急ぐ", "いそぐ", "hurry", .u),
        Verb("話す", "はなす", "speak", .u),
        Verb("貸す", "かす", "lend", .u),
        Verb("出す", "だす", "take out, submit", .u),
        Verb("待つ", "まつ", "wait", .u),
        Verb("持つ", "もつ", "hold, carry", .u),
        Verb("立つ", "たつ", "stand", .u),
        Verb("死ぬ", "しぬ", "die", .u),
        Verb("遊ぶ", "あそぶ", "play, hang out", .u),
        Verb("呼ぶ", "よぶ", "call", .u),
        Verb("選ぶ", "えらぶ", "choose", .u),
        Verb("買う", "かう", "buy", .u),
        Verb("会う", "あう", "meet", .u),
        Verb("使う", "つかう", "use", .u),
        Verb("言う", "いう", "say", .u),
        Verb("手伝う", "てつだう", "help", .u),
        Verb("歌う", "うたう", "sing", .u),
        Verb("帰る", "かえる", "go home", .u),
        Verb("入る", "はいる", "enter", .u),
        Verb("走る", "はしる", "run", .u),
        Verb("切る", "きる", "cut", .u),
        Verb("作る", "つくる", "make", .u),
        Verb("乗る", "のる", "ride", .u),
        Verb("送る", "おくる", "send", .u),
        Verb("する", "する", "do", .suru),
        Verb("勉強する", "べんきょうする", "study", .suru),
        Verb("運転する", "うんてんする", "drive", .suru),
        Verb("説明する", "せつめいする", "explain", .suru),
        Verb("心配する", "しんぱいする", "worry", .suru),
        Verb("来る", "くる", "come", .kuru),
    ]

    /// Whether drills should ask for this form of the verb. Skips forms that are odd to drill.
    func drills(_ form: VerbForm) -> Bool {
        switch form {
        case .imperative: kanji != "死ぬ"
        default: true
        }
    }
}
