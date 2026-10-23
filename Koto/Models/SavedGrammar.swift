import Foundation
import SwiftData

/// A grammar pattern the user saved to their grammar deck.
@Model
final class SavedGrammar: Reviewable {
    @Attribute(.unique) var pattern: String
    var meaning: String
    /// The textbook (Genki) form this is a casual version of, if any.
    var base: String?
    var note: String
    /// JSON-encoded [GrammarPoint.Example].
    var examplesData: Data
    var addedAt: Date
    var dueAt: Date

    var stability: Double = 0
    var difficulty: Double = 0
    var lastReviewedAt: Date?
    var reviewCount: Int = 0
    var lapses: Int = 0

    /// The chat sentence the pattern was saved from.
    var exampleSentence: String?
    var exampleTranslation: String?

    init(_ point: GrammarPoint, example: ExampleSentence? = nil) {
        pattern = point.pattern
        meaning = point.meaning
        base = point.base
        note = point.note
        examplesData = (try? JSONEncoder().encode(point.examples)) ?? Data()
        addedAt = .now
        dueAt = .now
        exampleSentence = example?.text
        exampleTranslation = example?.translation
    }

    var examples: [GrammarPoint.Example] {
        (try? JSONDecoder().decode([GrammarPoint.Example].self, from: examplesData)) ?? []
    }

    var grammarPoint: GrammarPoint {
        GrammarPoint(pattern: pattern, meaning: meaning, base: base, note: note, examples: examples)
    }
}

nonisolated extension SavedGrammar: ReviewCard {
    var cardFront: String { pattern }
    var cardReading: String? { base.map { "from \($0)" } }
    var cardMeaning: String { meaning }
    var cardNote: String? { note }
    var cardExample: String? { exampleSentence ?? examples.first?.japanese }
    var cardExampleTranslation: String? { exampleSentence == nil ? examples.first?.english : exampleTranslation }
    var cardSpeech: String { cardExample ?? pattern.replacingOccurrences(of: "〜", with: "") }
    var cardHighlight: String { pattern.replacingOccurrences(of: "〜", with: "") }
}

/// One grammar mistake こと corrected, kept for the "common mistakes" view even if the chat is cleared.
@Model
final class MistakeRecord {
    var point: String
    var original: String
    var suggested: String?
    var explanation: String
    var date: Date

    init(point: String, correction: Correction, date: Date = .now) {
        self.point = point
        original = correction.original
        suggested = correction.suggested
        explanation = correction.explanation
        self.date = date
    }
}
