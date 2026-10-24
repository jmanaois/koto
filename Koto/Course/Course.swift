import Foundation

/// A unit of the built-in grammar course: a handful of related lessons.
nonisolated struct CourseUnit: Identifiable {
    let id: Int
    let title: String
    let summary: String
    let lessons: [CourseLesson]
    /// JLPT level, shown in the unit header.
    var level = "N5"
}

/// One grammar point: an explainer card, then exercises. Finishing it adds the point to the grammar deck.
nonisolated struct CourseLesson: Identifiable, Hashable {
    let id: String
    /// Saved to the grammar deck under `point.pattern`, which is how reviews find the lesson again.
    let point: GrammarPoint
    /// How the pattern is built, e.g. "Noun + の + Noun".
    let formation: String
    /// Text that ties a Mistakes-log grammar point to this lesson, besides the pattern itself.
    let mistakeKeywords: [String]
    let exercises: [Exercise]

    /// Whether a grammar point name from the Mistakes log is about this lesson.
    func matches(mistakePoint: String) -> Bool {
        let point = mistakePoint.lowercased()
        let pattern = self.point.pattern.replacingOccurrences(of: "〜", with: "")
        return point.contains(pattern.lowercased()) || mistakeKeywords.contains { point.contains($0.lowercased()) }
    }
}

nonisolated enum Exercise: Hashable {
    /// Pick what goes in the blank (＿＿). The first option is right; they're shuffled when shown.
    case choice(sentence: String, english: String, options: [String])
    /// Put tiles in order to make the sentence. `chunks` is the answer in order, with each part's
    /// role for the structure view; `extras` are decoy tiles.
    case build(english: String, chunks: [MessageExplanation.Chunk], extras: [String])
    /// Type the Japanese for an English sentence. Any of `answers` is right; anything else is checked by Claude.
    case translate(english: String, answers: [String])
    /// Type `verb` in `forms`, applied in order: [.passive, .past] → 食べられた. Checked on the device.
    case conjugate(verb: Verb, forms: [VerbForm])

    static let blank = "＿＿"
    /// A choice option meaning "no particle here".
    static let nothing = "∅"

    var english: String {
        switch self {
        case .choice(_, let english, _), .build(let english, _, _), .translate(let english, _): english
        case .conjugate(let verb, let forms): "\(verb.kanji) (\(verb.english)) → \(forms.map(\.shortLabel).joined(separator: " + "))"
        }
    }

    /// The finished Japanese sentence, shown after answering.
    var answerSentence: String {
        switch self {
        case .choice(let sentence, _, let options):
            sentence.replacingOccurrences(of: Self.blank, with: options[0] == Self.nothing ? "" : options[0])
        case .build(_, let chunks, _):
            chunks.map(\.text).joined()
        case .translate(_, let answers):
            answers[0]
        case .conjugate(let verb, let forms):
            Conjugator.conjugate(verb, forms).kanji
        }
    }

    /// The answer split into parts by role, with neighboring parts of the same role merged.
    var structure: [MessageExplanation.Chunk]? {
        guard case .build(_, let chunks, _) = self else { return nil }
        var merged: [MessageExplanation.Chunk] = []
        for chunk in chunks {
            if let last = merged.last, last.role == chunk.role {
                merged[merged.count - 1] = MessageExplanation.Chunk(text: last.text + chunk.text, role: chunk.role)
            } else {
                merged.append(chunk)
            }
        }
        return merged
    }

    /// Everything but translations is checked on the device, so it works offline.
    var isOffline: Bool {
        if case .translate = self { return false }
        return true
    }

    /// Answered by typing rather than tapping.
    var isTyped: Bool {
        switch self {
        case .translate, .conjugate: true
        case .choice, .build: false
        }
    }

    /// Text compared when checking a typed answer: kana readings, hiragana, no punctuation or spaces.
    /// So 私は学生です and わたしはがくせいです match.
    static func comparable(_ text: String) -> String {
        let kana = Furigana.tokens(for: text)
            .flatMap(\.runs)
            .map { $0.reading ?? $0.text }
            .joined()
        let hiragana = kana.applyingTransform(.hiraganaToKatakana, reverse: true) ?? kana
        let dropped = CharacterSet.punctuationCharacters.union(.whitespacesAndNewlines).union(.symbols)
        return String(String.UnicodeScalarView(hiragana.unicodeScalars.filter { !dropped.contains($0) }))
    }
}

/// Every unit, in the order they're taught: N5 grammar, verb conjugation, then N4 and N3.
/// Unit ids are used for placement checks, so they're unique across levels.
nonisolated enum Curriculum {
    static let units: [CourseUnit] = N5Course.units + ConjugationCourse.units + N4Course.units + N3Course.units

    static let lessons: [CourseLesson] = units.flatMap(\.lessons)

    static func lesson(id: String) -> CourseLesson? {
        lessons.first { $0.id == id }
    }

    static func lesson(pattern: String) -> CourseLesson? {
        lessons.first { $0.point.pattern == pattern }
    }

    static func unit(of lesson: CourseLesson) -> CourseUnit? {
        units.first { $0.lessons.contains(lesson) }
    }
}

// MARK: - Writing lessons

/// Short helpers so the course content reads like a list.
nonisolated protocol CourseWriting {}

nonisolated extension CourseWriting {
    static func lesson(
        _ id: String, _ pattern: String, _ meaning: String,
        form: String, note: String, examples: [(String, String)], keywords: [String] = [],
        _ exercises: Exercise...
    ) -> CourseLesson {
        lesson(id, pattern, meaning, form: form, note: note, examples: examples, keywords: keywords, exercises: exercises)
    }

    /// Same as above, for exercises built as a list (drills plus a few sentences).
    static func lesson(
        _ id: String, _ pattern: String, _ meaning: String,
        form: String, note: String, examples: [(String, String)], keywords: [String] = [],
        exercises: [Exercise]
    ) -> CourseLesson {
        CourseLesson(
            id: id,
            point: GrammarPoint(
                pattern: pattern, meaning: meaning, base: nil, note: note,
                examples: examples.map { GrammarPoint.Example(japanese: $0.0, english: $0.1) }
            ),
            formation: form,
            mistakeKeywords: keywords,
            exercises: exercises
        )
    }

    static func pick(_ sentence: String, _ english: String, _ options: String...) -> Exercise {
        .choice(sentence: sentence, english: english, options: options)
    }

    /// `spec` is the answer split into tiles by spaces, each optionally tagged with a role:
    /// "私は/t 学生です。/v". Roles: t topic, s subject, o object, tm time, p place, g target,
    /// v verb, d description, e ending, c connector; untagged is other.
    static func build(_ english: String, _ spec: String, extra: String...) -> Exercise {
        let roles: [String: MessageExplanation.Chunk.Role] = [
            "t": .topic, "s": .subject, "o": .object, "tm": .time, "p": .place, "g": .target,
            "v": .verb, "d": .description, "e": .ending, "c": .connector,
        ]
        let chunks = spec.split(separator: " ").map { part in
            let pieces = part.split(separator: "/", maxSplits: 1)
            let role = pieces.count == 2 ? roles[String(pieces[1])] ?? .other : .other
            return MessageExplanation.Chunk(text: String(pieces[0]), role: role)
        }
        return .build(english: english, chunks: chunks, extras: extra)
    }

    static func say(_ english: String, _ answers: String...) -> Exercise {
        .translate(english: english, answers: answers)
    }

    /// Conjugate each verb (by its kanji in `Verb.pool`) into `forms`.
    static func drill(_ forms: VerbForm..., verbs: String...) -> [Exercise] {
        verbs.map { .conjugate(verb: Verb.named($0), forms: forms) }
    }

    /// Conjugate one verb through a chain of forms: conj("飲む", .causative, .past) → 飲ませた.
    static func conj(_ verb: String, _ forms: VerbForm...) -> Exercise {
        .conjugate(verb: Verb.named(verb), forms: forms)
    }
}
