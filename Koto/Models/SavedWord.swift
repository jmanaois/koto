import Foundation
import SwiftData

/// A word the user saved to their deck. Stored on device with SwiftData.
@Model
final class SavedWord: Reviewable {
    @Attribute(.unique) var word: String
    var reading: String
    var meaning: String
    var addedAt: Date
    /// When the word is next due for review. New words are due immediately.
    var dueAt: Date

    // FSRS memory state. Only meaningful once lastReviewedAt is set.
    var stability: Double = 0
    var difficulty: Double = 0
    var lastReviewedAt: Date?
    var reviewCount: Int = 0
    var lapses: Int = 0

    /// The chat sentence the word was saved from, and its translation if known.
    var exampleSentence: String?
    var exampleTranslation: String?

    /// FSRS stability, in days, at which a word counts as known well and its furigana fades.
    /// A new word gets there after about four or five Good reviews in a row.
    static let knownWellStability = 30.0

    var isKnownWell: Bool {
        lastReviewedAt != nil && stability >= Self.knownWellStability
    }

    init(_ item: VocabItem, example: ExampleSentence? = nil) {
        word = item.word
        reading = item.reading
        meaning = item.meaning
        addedAt = .now
        dueAt = .now
        exampleSentence = example?.text
        exampleTranslation = example?.translation
    }
}

nonisolated extension SavedWord: ReviewCard {
    var cardFront: String { word }
    var cardReading: String? { reading == word ? nil : reading }
    var cardMeaning: String { meaning }
    var cardNote: String? { nil }
    var cardExample: String? { exampleSentence }
    var cardExampleTranslation: String? { exampleTranslation }
    var cardSpeech: String { reading }
    var cardHighlight: String { word }
}
