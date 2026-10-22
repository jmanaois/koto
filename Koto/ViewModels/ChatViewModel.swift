import Foundation
import Observation
import SwiftData

@Observable
final class ChatViewModel {
    private(set) var messages: [ChatMessage] = []
    var draft = ""
    private(set) var isBotTyping = false

    private let service: ChatService
    private let context: ModelContext
    /// Saved copies of `messages`, by id, so later changes can be written back.
    private var stored: [UUID: StoredMessage] = [:]

    init(context: ModelContext, service: ChatService = ClaudeChatService()) {
        self.context = context
        self.service = service

        let saved = (try? context.fetch(FetchDescriptor<StoredMessage>(sortBy: [SortDescriptor(\.date)]))) ?? []
        for message in saved {
            stored[message.id] = message
        }
        messages = saved.map(\.chatMessage)

        if messages.isEmpty {
            append(ChatMessage(sender: .bot, text: "やっほー！ことだよ👋\n日本語でなんでも話しかけてね。変なところがあったら直すよ！"))
        }
    }

    var canSend: Bool {
        !isBotTyping && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Sends `text` if given (e.g. from a sample chip), otherwise the current draft.
    func send(_ text: String? = nil) {
        let body = (text ?? draft).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, !isBotTyping else { return }
        if text == nil { draft = "" }

        append(ChatMessage(sender: .user, text: body))
        let userIndex = messages.count - 1
        isBotTyping = true

        let history = messages.filter { !$0.isError }
        let practiceWords = duePracticeWords()
        Task {
            defer { isBotTyping = false }
            do {
                let response = try await service.reply(to: history, practiceWords: practiceWords)
                let reviewed = reviewPracticedWords(response.practicedWords, offered: practiceWords)
                update(at: userIndex) {
                    $0.corrections = response.corrections
                    $0.practicedWords = reviewed
                    $0.isRead = true
                }
                append(ChatMessage(sender: .bot, text: response.reply, vocab: response.newVocab))
            } catch {
                // Shown, but not saved or sent back to the bot.
                messages.append(ChatMessage(
                    sender: .bot,
                    text: "ごめん、エラーが出ちゃった🙏\n\(error.localizedDescription)",
                    isError: true
                ))
            }
        }
    }

    /// The most overdue words in the deck, for the bot to work into its reply.
    private func duePracticeWords(limit: Int = 5) -> [VocabItem] {
        let now = Date.now
        var descriptor = FetchDescriptor<SavedWord>(
            predicate: #Predicate { $0.dueAt <= now },
            sortBy: [SortDescriptor(\.dueAt)]
        )
        descriptor.fetchLimit = limit
        let words = (try? context.fetch(descriptor)) ?? []
        return words.map { VocabItem(word: $0.word, reading: $0.reading, meaning: $0.meaning) }
    }

    /// Using a due word correctly in chat counts as remembering it (rated Good).
    /// Only words that were actually offered as practice words count.
    /// - Returns: the words that were reviewed.
    private func reviewPracticedWords(_ used: [String], offered: [VocabItem]) -> [String] {
        let offeredWords = Set(offered.map(\.word))
        let words = used.filter(offeredWords.contains)
        guard !words.isEmpty else { return [] }

        let now = Date.now
        let descriptor = FetchDescriptor<SavedWord>(predicate: #Predicate { words.contains($0.word) && $0.dueAt <= now })
        let saved = (try? context.fetch(descriptor)) ?? []
        for word in saved {
            word.review(.good)
        }
        save()
        return saved.map(\.word)
    }

    /// Fetches and saves an English translation and breakdown of a bot message.
    func explain(_ id: UUID) async throws {
        guard let index = messages.firstIndex(where: { $0.id == id }), messages[index].explanation == nil else { return }
        let context = Array(messages[..<index].filter { !$0.isError }.suffix(4))
        let explanation = try await service.explain(messages[index].text, context: context)
        if let index = messages.firstIndex(where: { $0.id == id }) {
            update(at: index) { $0.explanation = explanation }
        }
    }

    // MARK: - Persistence

    private func append(_ message: ChatMessage) {
        messages.append(message)
        let saved = StoredMessage(message)
        context.insert(saved)
        stored[message.id] = saved
        save()
    }

    private func update(at index: Int, _ change: (inout ChatMessage) -> Void) {
        change(&messages[index])
        stored[messages[index].id]?.update(from: messages[index])
        save()
    }

    private func save() {
        try? context.save()
    }
}
