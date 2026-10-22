import Foundation
import SwiftData

/// A word the user saved to their deck. Stored on device with SwiftData.
@Model
final class SavedWord {
    @Attribute(.unique) var word: String
    var reading: String
    var meaning: String
    var addedAt: Date
    /// When the word is next due for review. Spaced repetition will move this forward;
    /// for now every new word is due immediately.
    var dueAt: Date

    init(_ item: VocabItem) {
        word = item.word
        reading = item.reading
        meaning = item.meaning
        addedAt = .now
        dueAt = .now
    }
}
