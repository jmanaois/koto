import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// A JSON copy of everything worth keeping: saved words (with review history) and chats.
/// Exported to the Files app so it survives deleting the app.
nonisolated struct Backup: Codable {
    struct Word: Codable {
        var word, reading, meaning: String
        var addedAt, dueAt: Date
        var stability, difficulty: Double
        var lastReviewedAt: Date?
        var reviewCount, lapses: Int
        var exampleSentence, exampleTranslation: String?
    }

    struct Message: Codable {
        var id: UUID
        var isFromUser: Bool
        var text: String
        var speaker, mode: String?
        var date: Date
        var isRead: Bool
        var correctionsData, vocabData, practicedData: Data
        var explanationData: Data?
        var grammarData: Data?
    }

    struct Grammar: Codable {
        var pattern, meaning, note: String
        var base: String?
        var examplesData: Data
        var addedAt, dueAt: Date
        var stability, difficulty: Double
        var lastReviewedAt: Date?
        var reviewCount, lapses: Int
        var exampleSentence, exampleTranslation: String?
    }

    struct Mistake: Codable {
        var point, original, explanation: String
        var suggested: String?
        var date: Date
    }

    struct Lesson: Codable {
        var lessonID: String
        var completedAt: Date
        var testedOut: Bool
    }

    struct Day: Codable {
        var day: Date
        var exercises, correct: Int
    }

    var version = 1
    var exportedAt = Date()
    var words: [Word]
    var messages: [Message]
    // Added after the first version; missing in older backup files.
    var grammar: [Grammar]?
    var mistakes: [Mistake]?
    var lessons: [Lesson]?
    var studyDays: [Day]?

    /// What an import added or changed, for the confirmation message.
    struct ImportSummary {
        var wordsAdded = 0
        var wordsUpdated = 0
        var messagesAdded = 0
        var grammarAdded = 0
        var lessonsAdded = 0
    }

    enum ImportError: LocalizedError {
        case unreadable
        case newerVersion

        var errorDescription: String? {
            switch self {
            case .unreadable: "That file isn't a Koto backup."
            case .newerVersion: "That backup was made by a newer version of Koto."
            }
        }
    }
}

extension Backup {
    @MainActor
    init(from context: ModelContext) throws {
        words = try context.fetch(FetchDescriptor<SavedWord>()).map { word in
            Word(
                word: word.word, reading: word.reading, meaning: word.meaning,
                addedAt: word.addedAt, dueAt: word.dueAt,
                stability: word.stability, difficulty: word.difficulty,
                lastReviewedAt: word.lastReviewedAt, reviewCount: word.reviewCount, lapses: word.lapses,
                exampleSentence: word.exampleSentence, exampleTranslation: word.exampleTranslation
            )
        }
        messages = try context.fetch(FetchDescriptor<StoredMessage>(sortBy: [SortDescriptor(\.date)])).map { message in
            Message(
                id: message.id, isFromUser: message.isFromUser, text: message.text,
                speaker: message.speaker, mode: message.mode, date: message.date, isRead: message.isRead,
                correctionsData: message.correctionsData, vocabData: message.vocabData,
                practicedData: message.practicedData, explanationData: message.explanationData,
                grammarData: message.grammarData
            )
        }
        grammar = try context.fetch(FetchDescriptor<SavedGrammar>()).map { item in
            Grammar(
                pattern: item.pattern, meaning: item.meaning, note: item.note, base: item.base,
                examplesData: item.examplesData, addedAt: item.addedAt, dueAt: item.dueAt,
                stability: item.stability, difficulty: item.difficulty, lastReviewedAt: item.lastReviewedAt,
                reviewCount: item.reviewCount, lapses: item.lapses,
                exampleSentence: item.exampleSentence, exampleTranslation: item.exampleTranslation
            )
        }
        mistakes = try context.fetch(FetchDescriptor<MistakeRecord>()).map { record in
            Mistake(
                point: record.point, original: record.original, explanation: record.explanation,
                suggested: record.suggested, date: record.date
            )
        }
        lessons = try context.fetch(FetchDescriptor<LessonProgress>()).map {
            Lesson(lessonID: $0.lessonID, completedAt: $0.completedAt, testedOut: $0.testedOut)
        }
        studyDays = try context.fetch(FetchDescriptor<StudyDay>()).map {
            Day(day: $0.day, exercises: $0.exercises, correct: $0.correct)
        }
    }

    static func decode(_ data: Data) throws -> Backup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let backup = try? decoder.decode(Backup.self, from: data) else { throw ImportError.unreadable }
        guard backup.version <= 1 else { throw ImportError.newerVersion }
        return backup
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    /// Adds what's missing on this device without deleting anything. A word that exists in
    /// both places keeps whichever copy has more review history; messages are matched by id.
    @MainActor
    func merge(into context: ModelContext) throws -> ImportSummary {
        var summary = ImportSummary()

        let existingWords = Dictionary(
            try context.fetch(FetchDescriptor<SavedWord>()).map { ($0.word, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        for record in words {
            if let existing = existingWords[record.word] {
                guard record.reviewCount > existing.reviewCount else { continue }
                apply(record, to: existing)
                summary.wordsUpdated += 1
            } else {
                let word = SavedWord(VocabItem(word: record.word, reading: record.reading, meaning: record.meaning))
                apply(record, to: word)
                context.insert(word)
                summary.wordsAdded += 1
            }
        }

        let existingIDs = Set(try context.fetch(FetchDescriptor<StoredMessage>()).map(\.id))
        for record in messages where !existingIDs.contains(record.id) {
            let message = StoredMessage(
                ChatMessage(
                    id: record.id,
                    sender: record.isFromUser ? .user : .bot,
                    text: record.text,
                    speaker: record.speaker,
                    date: record.date,
                    isRead: record.isRead
                ),
                mode: .friend
            )
            message.mode = record.mode
            message.correctionsData = record.correctionsData
            message.vocabData = record.vocabData
            message.practicedData = record.practicedData
            message.explanationData = record.explanationData
            message.grammarData = record.grammarData
            context.insert(message)
            summary.messagesAdded += 1
        }

        let existingGrammar = Dictionary(
            try context.fetch(FetchDescriptor<SavedGrammar>()).map { ($0.pattern, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        for record in grammar ?? [] {
            let point = GrammarPoint(pattern: record.pattern, meaning: record.meaning, base: record.base, note: record.note, examples: [])
            let target: SavedGrammar
            if let existing = existingGrammar[record.pattern] {
                guard record.reviewCount > existing.reviewCount else { continue }
                target = existing
            } else {
                target = SavedGrammar(point)
                context.insert(target)
                summary.grammarAdded += 1
            }
            target.examplesData = record.examplesData
            target.addedAt = record.addedAt
            target.dueAt = record.dueAt
            target.stability = record.stability
            target.difficulty = record.difficulty
            target.lastReviewedAt = record.lastReviewedAt
            target.reviewCount = record.reviewCount
            target.lapses = record.lapses
            target.exampleSentence = record.exampleSentence ?? target.exampleSentence
            target.exampleTranslation = record.exampleTranslation ?? target.exampleTranslation
        }

        // Mistakes have no id; skip ones already logged at the same moment for the same text.
        let existingMistakes = Set(try context.fetch(FetchDescriptor<MistakeRecord>()).map { "\($0.date.timeIntervalSince1970)|\($0.original)" })
        for record in mistakes ?? [] where !existingMistakes.contains("\(record.date.timeIntervalSince1970)|\(record.original)") {
            let correction = Correction(original: record.original, suggested: record.suggested, type: .grammar, explanation: record.explanation)
            context.insert(MistakeRecord(point: record.point, correction: correction, date: record.date))
        }

        let existingLessons = Set(try context.fetch(FetchDescriptor<LessonProgress>()).map(\.lessonID))
        for record in lessons ?? [] where !existingLessons.contains(record.lessonID) {
            context.insert(LessonProgress(lessonID: record.lessonID, completedAt: record.completedAt, testedOut: record.testedOut))
            summary.lessonsAdded += 1
        }

        let existingDays = Set(try context.fetch(FetchDescriptor<StudyDay>()).map(\.day))
        for record in studyDays ?? [] where !existingDays.contains(record.day) {
            context.insert(StudyDay(day: record.day, exercises: record.exercises, correct: record.correct))
        }

        try context.save()
        return summary
    }

    @MainActor
    private func apply(_ record: Word, to word: SavedWord) {
        word.reading = record.reading
        word.meaning = record.meaning
        word.addedAt = record.addedAt
        word.dueAt = record.dueAt
        word.stability = record.stability
        word.difficulty = record.difficulty
        word.lastReviewedAt = record.lastReviewedAt
        word.reviewCount = record.reviewCount
        word.lapses = record.lapses
        word.exampleSentence = record.exampleSentence ?? word.exampleSentence
        word.exampleTranslation = record.exampleTranslation ?? word.exampleTranslation
    }
}

/// Lets SwiftUI's file exporter save a backup to the Files app.
struct BackupDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
