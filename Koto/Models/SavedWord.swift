import Foundation
import SwiftData

/// A word the user saved to their deck. Stored on device with SwiftData.
@Model
final class SavedWord {
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

    init(_ item: VocabItem, example: ExampleSentence? = nil) {
        word = item.word
        reading = item.reading
        meaning = item.meaning
        addedAt = .now
        dueAt = .now
        exampleSentence = example?.text
        exampleTranslation = example?.translation
    }

    private var memoryState: FSRS.MemoryState? {
        lastReviewedAt == nil ? nil : FSRS.MemoryState(stability: stability, difficulty: difficulty)
    }

    /// What would happen if the word were rated `rating` now, without changing anything.
    func preview(_ rating: FSRS.Rating, now: Date = .now) -> FSRS.Result {
        let elapsedDays = lastReviewedAt.map { now.timeIntervalSince($0) / 86_400 } ?? 0
        return FSRS.next(state: memoryState, elapsedDays: elapsedDays, rating: rating)
    }

    func review(_ rating: FSRS.Rating, now: Date = .now) {
        let result = preview(rating, now: now)
        if rating == .again, memoryState != nil {
            lapses += 1
        }
        stability = result.state.stability
        difficulty = result.state.difficulty
        lastReviewedAt = now
        dueAt = now.addingTimeInterval(result.interval)
        reviewCount += 1
    }
}
