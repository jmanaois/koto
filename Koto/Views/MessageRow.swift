import SwiftData
import SwiftUI

struct MessageRow: View {
    let message: ChatMessage
    /// Name and avatar for a bot message's speaker.
    let persona: Persona
    let onVocabTap: (VocabItem) -> Void
    /// Called with the text starting at a tapped word, for dictionary lookup.
    let onWordTap: (String) -> Void
    /// Opens the translation and breakdown of a bot message.
    let onTranslate: () -> Void

    var body: some View {
        switch message.sender {
        case .bot: botRow
        case .user: userRow
        }
    }

    private var botRow: some View {
        HStack(alignment: .top, spacing: 8) {
            BotAvatar(persona: persona)
            VStack(alignment: .leading, spacing: 4) {
                Text(persona.name)
                    .font(.caption)
                    .foregroundStyle(Theme.metaText)
                HStack(alignment: .bottom, spacing: 4) {
                    Bubble(text: message.text, sender: .bot, onWordTap: onWordTap)
                    TimeLabel(date: message.date)
                }
                if !message.isError {
                    HStack(spacing: 6) {
                        TranslateButton(action: onTranslate)
                        VocabChips(items: message.vocab, onTap: onVocabTap)
                    }
                }
            }
            Spacer(minLength: 40)
        }
    }

    private var userRow: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack(alignment: .bottom, spacing: 4) {
                Spacer(minLength: 60)
                VStack(alignment: .trailing, spacing: 0) {
                    if message.isRead {
                        Text("既読")
                    }
                    TimeLabel(date: message.date)
                }
                .font(.caption2)
                .foregroundStyle(Theme.metaText)
                Bubble(text: message.text, sender: .user, onWordTap: onWordTap)
            }
            if !message.practicedWords.isEmpty {
                ReviewedBadge(words: message.practicedWords)
            }
            if !message.corrections.isEmpty {
                CorrectionsView(corrections: message.corrections)
                    .padding(.leading, 40)
            }
        }
    }
}

private struct Bubble: View {
    let text: String
    let sender: Sender
    let onWordTap: (String) -> Void

    private var textColor: Color {
        sender == .user ? Theme.userBubbleText : .primary
    }

    var body: some View {
        FuriganaText(text, onWordTap: onWordTap)
            .font(.body)
            .foregroundStyle(textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                sender == .user ? Theme.userBubble : Theme.botBubble,
                // The sharp corner points toward the speaker, like LINE's bubble tail.
                in: UnevenRoundedRectangle(
                    topLeadingRadius: sender == .bot ? 4 : 18,
                    bottomLeadingRadius: 18,
                    bottomTrailingRadius: 18,
                    topTrailingRadius: sender == .user ? 4 : 18
                )
            )
            // Words are laid out individually, so offer Copy instead of text selection.
            .contextMenu {
                Button("Copy", systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = text
                }
            }
    }
}

private struct TimeLabel: View {
    let date: Date

    var body: some View {
        Text(date, format: .dateTime.hour().minute())
            .font(.caption2)
            .foregroundStyle(Theme.metaText)
    }
}

struct BotAvatar: View {
    let persona: Persona

    var body: some View {
        Text(persona.initial)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(Color(light: persona.color, dark: persona.color), in: Circle())
    }
}

private struct TranslateButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Translate", systemImage: "character.bubble")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.white.opacity(0.85), in: Capsule())
                .foregroundStyle(.black)
        }
        .buttonStyle(.plain)
    }
}

/// Shown under a user message when it used due practice words correctly.
private struct ReviewedBadge: View {
    let words: [String]

    var body: some View {
        Label("Reviewed \(words.joined(separator: "、"))", systemImage: "checkmark.circle.fill")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white.opacity(0.9), in: Capsule())
            .foregroundStyle(.green)
    }
}

private struct VocabChips: View {
    let items: [VocabItem]
    let onTap: (VocabItem) -> Void

    @Query private var savedWords: [SavedWord]

    var body: some View {
        let saved = Set(savedWords.map(\.word))
        HStack(spacing: 6) {
            ForEach(items) { item in
                let isSaved = saved.contains(item.word)
                Button {
                    onTap(item)
                } label: {
                    Label {
                        Text(item.word)
                    } icon: {
                        Image(systemName: isSaved ? "book.closed.fill" : "book.closed")
                            .foregroundStyle(isSaved ? .green : .black)
                    }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.85), in: Capsule())
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct TypingIndicatorRow: View {
    let persona: Persona

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            BotAvatar(persona: persona)
            Image(systemName: "ellipsis")
                .font(.title3)
                .symbolEffect(.variableColor.iterative, options: .repeating)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Theme.botBubble, in: UnevenRoundedRectangle(
                    topLeadingRadius: 4, bottomLeadingRadius: 18, bottomTrailingRadius: 18, topTrailingRadius: 18
                ))
                .padding(.top, 18)
            Spacer()
        }
        .accessibilityLabel("\(persona.name) is typing")
    }
}
