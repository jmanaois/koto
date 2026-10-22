import Foundation
import Observation
import SwiftData

@Observable
final class ChatViewModel {
    private(set) var messages: [ChatMessage] = []
    var draft = ""
    private(set) var isBotTyping = false

    /// Who the user is chatting with. Each mode keeps its own conversation.
    var mode: ChatMode {
        didSet {
            guard mode != oldValue else { return }
            UserDefaults.standard.set(mode.rawValue, forKey: Self.modeKey)
            draft = ""
            loadMessages()
        }
    }

    private let service: ChatService
    private let context: ModelContext
    /// Saved copies of `messages`, by id, so later changes can be written back.
    private var stored: [UUID: StoredMessage] = [:]

    private static let modeKey = "chatMode"

    init(context: ModelContext, service: ChatService = ClaudeChatService()) {
        self.context = context
        self.service = service
        mode = UserDefaults.standard.string(forKey: Self.modeKey).flatMap(ChatMode.init(rawValue:)) ?? .friend
        loadMessages()
    }

    var canSend: Bool {
        !isBotTyping && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Sends `text` if given, otherwise the current draft.
    func send(_ text: String? = nil) {
        let body = (text ?? draft).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, !isBotTyping else { return }
        if text == nil { draft = "" }

        append(ChatMessage(sender: .user, text: body))
        let userIndex = messages.count - 1
        isBotTyping = true

        let history = messages.filter { !$0.isError }
        let practiceWords = duePracticeWords()
        let mode = mode
        Task {
            defer { isBotTyping = false }
            do {
                let response = try await service.reply(to: history, practiceWords: practiceWords, mode: mode)
                // The user may have switched modes while waiting; this reply belongs to the old chat.
                guard mode == self.mode else { return }
                let reviewed = reviewPracticedWords(response.practicedWords, offered: practiceWords)
                update(at: userIndex) {
                    $0.corrections = response.corrections
                    $0.practicedWords = reviewed
                    $0.isRead = true
                }
                let parts = Self.splitReply(response.reply, for: mode)
                for (index, part) in parts.enumerated() {
                    // New vocab goes under the last message of the reply.
                    let vocab = index == parts.count - 1 ? response.newVocab : []
                    append(ChatMessage(sender: .bot, text: part.text, speaker: part.speaker, vocab: vocab))
                }
            } catch {
                guard mode == self.mode else { return }
                // Shown, but not saved or sent back to the bot.
                messages.append(ChatMessage(
                    sender: .bot,
                    text: "ごめん、エラーが出ちゃった🙏\n\(error.localizedDescription)",
                    isError: true
                ))
            }
        }
    }

    /// In a group chat the model writes one "名前：message" line per speaker; split those into
    /// separate bubbles. Lines without a known name stay with the message before them.
    static func splitReply(_ reply: String, for mode: ChatMode) -> [(speaker: String?, text: String)] {
        guard mode == .group else { return [(nil, reply)] }

        var parts: [(speaker: String?, text: String)] = []
        for line in reply.split(separator: "\n") {
            let line = line.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }
            if let speaker = ChatMode.groupSpeakers.first(where: { line.hasPrefix($0 + "：") || line.hasPrefix($0 + ":") }) {
                let text = line.dropFirst(speaker.count + 1).trimmingCharacters(in: .whitespaces)
                parts.append((speaker, text))
            } else if !parts.isEmpty {
                parts[parts.count - 1].text += "\n" + line
            } else {
                parts.append((ChatMode.groupSpeakers[0], line))
            }
        }
        return parts.isEmpty ? [(ChatMode.groupSpeakers[0], reply)] : parts
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
        guard let index = messages.firstIndex(where: { $0.id == id }),
              messages[index].explanation?.isComplete != true
        else { return }
        let context = Array(messages[..<index].filter { !$0.isError }.suffix(4))
        let explanation = try await service.explain(messages[index].text, context: context)
        if let index = messages.firstIndex(where: { $0.id == id }) {
            update(at: index) { $0.explanation = explanation }
        }
    }

    // MARK: - Persistence

    /// Loads the current mode's conversation, starting it with the mode's welcome if it's empty.
    private func loadMessages() {
        let modeName: String? = mode.rawValue
        // Messages saved before modes existed have no mode and belong to the friend chat.
        let includesUntagged = mode == .friend
        let descriptor = FetchDescriptor<StoredMessage>(
            predicate: #Predicate { $0.mode == modeName || (includesUntagged && $0.mode == nil) },
            sortBy: [SortDescriptor(\.date)]
        )
        let saved = (try? context.fetch(descriptor)) ?? []
        stored = Dictionary(uniqueKeysWithValues: saved.map { ($0.id, $0) })
        messages = saved.map(\.chatMessage)

        if messages.isEmpty {
            for (speaker, text) in mode.welcome {
                append(ChatMessage(sender: .bot, text: text, speaker: speaker))
            }
        }
    }

    private func append(_ message: ChatMessage) {
        messages.append(message)
        let saved = StoredMessage(message, mode: mode)
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
