import Foundation
import SwiftData

/// Something reviewed with FSRS spaced repetition: saved words and saved grammar.
nonisolated protocol Reviewable: AnyObject {
    var dueAt: Date { get set }
    var stability: Double { get set }
    var difficulty: Double { get set }
    var lastReviewedAt: Date? { get set }
    var reviewCount: Int { get set }
    var lapses: Int { get set }
}

nonisolated extension Reviewable {
    private var memoryState: FSRS.MemoryState? {
        lastReviewedAt == nil ? nil : FSRS.MemoryState(stability: stability, difficulty: difficulty)
    }

    /// What would happen if the card were rated `rating` now, without changing anything.
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

/// A flashcard: what the review screen shows for a saved word or grammar pattern.
nonisolated protocol ReviewCard: Reviewable, PersistentModel {
    var cardFront: String { get }
    var cardReading: String? { get }
    var cardMeaning: String { get }
    /// Extra explanation under the meaning (grammar notes).
    var cardNote: String? { get }
    var cardExample: String? { get }
    var cardExampleTranslation: String? { get }
    /// What the speaker button reads aloud.
    var cardSpeech: String { get }
    /// What to emphasize in the example sentence.
    var cardHighlight: String { get }
}
