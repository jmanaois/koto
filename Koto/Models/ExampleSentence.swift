import Foundation

/// The chat sentence a word was saved from, shown on the back of its flashcard.
nonisolated struct ExampleSentence: Hashable {
    let text: String
    /// English translation, when one was already fetched for the whole message.
    let translation: String?

    /// The sentence in `message` that contains `word`, or nil if the message shouldn't be
    /// used as an example (a user message こと corrected, so it may contain mistakes).
    init?(from message: ChatMessage, containing word: String) {
        guard !message.isError, !(message.sender == .user && !message.corrections.isEmpty) else { return nil }

        let whole = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let sentence = Self.sentences(in: whole).first { $0.contains(word) } ?? whole
        guard !sentence.isEmpty else { return nil }

        text = sentence
        // The saved translation covers the whole message, so only reuse it when the
        // example is the whole message.
        translation = sentence == whole && message.explanation?.isComplete == true
            ? message.explanation?.translation
            : nil
    }

    /// Splits text after 。！？!? and at line breaks, keeping the punctuation.
    private static func sentences(in text: String) -> [String] {
        var sentences: [String] = []
        var current = ""
        for character in text {
            if character == "\n" {
                sentences.append(current)
                current = ""
                continue
            }
            current.append(character)
            if "。！？!?".contains(character) {
                sentences.append(current)
                current = ""
            }
        }
        sentences.append(current)
        return sentences
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
