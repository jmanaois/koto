import Foundation

/// The N4 grammar course, for after the N5 course and conjugation unit. Units are spread over
/// N4Course+*.swift. Lesson ids are stored in progress records, so never change one.
nonisolated enum N4Course: CourseWriting {
    static let units: [CourseUnit] = [unit7, unit8, unit9, unit10, unit11, unit12, unit13]
}
