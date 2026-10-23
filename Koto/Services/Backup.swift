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
    }

    var version = 1
    var exportedAt = Date()
    var words: [Word]
    var messages: [Message]

    /// What an import added or changed, for the confirmation message.
    struct ImportSummary {
        var wordsAdded = 0
        var wordsUpdated = 0
        var messagesAdded = 0
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
                practicedData: message.practicedData, explanationData: message.explanationData
            )
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
            context.insert(message)
            summary.messagesAdded += 1
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
