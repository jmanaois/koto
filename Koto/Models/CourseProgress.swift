import Foundation
import SwiftData

/// A course lesson the user finished or tested out of. Reviews after that go through the
/// grammar deck card with the lesson's pattern.
@Model
final class LessonProgress {
    @Attribute(.unique) var lessonID: String
    var completedAt: Date
    /// Passed the unit's placement check instead of doing the lesson.
    var testedOut: Bool

    init(lessonID: String, completedAt: Date = .now, testedOut: Bool = false) {
        self.lessonID = lessonID
        self.completedAt = completedAt
        self.testedOut = testedOut
    }
}

/// A day the daily lesson was finished, for the streak.
@Model
final class StudyDay {
    /// Start of the day, in the calendar the user was in at the time.
    @Attribute(.unique) var day: Date
    var exercises: Int
    var correct: Int

    init(day: Date, exercises: Int = 0, correct: Int = 0) {
        self.day = day
        self.exercises = exercises
        self.correct = correct
    }
}

nonisolated enum Streak {
    /// Days in a row with a finished daily lesson, ending today, or yesterday if today isn't done yet.
    static func count(_ days: [Date], now: Date = .now, calendar: Calendar = .current) -> Int {
        let studied = Set(days.map { calendar.startOfDay(for: $0) })
        var day = calendar.startOfDay(for: now)
        if !studied.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        var count = 0
        while studied.contains(day) {
            count += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }

    static func didStudyToday(_ days: [Date], now: Date = .now, calendar: Calendar = .current) -> Bool {
        days.contains { calendar.isDate($0, inSameDayAs: now) }
    }
}
