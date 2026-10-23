import SwiftUI

/// A word the user tapped or highlighted in a message, and what the dictionary found for it.
struct WordLookup: Identifiable {
    let id = UUID()
    /// Text from the tapped word onward (食べましたか), or exactly what was highlighted.
    let text: String
    /// True when the user highlighted `text` themselves, so it's shown with Listen and Copy.
    let isSelection: Bool
    let result: LookupResult?
    /// The sentence the word was found in, saved with the word for its flashcard.
    let example: ExampleSentence?

    init(text: String, in message: ChatMessage, isSelection: Bool = false) {
        self.text = text
        self.isSelection = isSelection
        result = JapaneseDictionary.shared.lookup(text, maxLength: isSelection ? 24 : 12)
        example = ExampleSentence(from: message, containing: result?.matched ?? text)
    }
}

struct WordLookupSheet: View {
    let lookup: WordLookup

    var body: some View {
        NavigationStack {
            List {
                if lookup.isSelection {
                    Section {
                        HStack(spacing: 12) {
                            FuriganaText(lookup.text, onWordTap: { _ in })
                                .font(.title3)
                            Spacer()
                            SpeakButton(text: lookup.text)
                            Button("Copy", systemImage: "doc.on.doc") {
                                UIPasteboard.general.string = lookup.text
                            }
                            .labelStyle(.iconOnly)
                            .font(.title3)
                            .buttonStyle(.borderless)
                        }
                    } header: {
                        Text("Highlighted")
                    } footer: {
                        if let matched = lookup.result?.matched, matched != lookup.text {
                            Text("Showing the dictionary word at the start: \(matched)")
                        }
                    }
                }

                if let result = lookup.result {
                    ForEach(result.entries) { entry in
                        Section {
                            EntryRow(entry: entry)
                            SaveWordButton(item: entry.vocabItem, example: lookup.example)
                                .frame(maxWidth: .infinity)
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No entry found",
                        systemImage: "magnifyingglass",
                        description: Text("Couldn't find \(lookup.text) in the dictionary.")
                    )
                }

                Section {
                } footer: {
                    Text("Dictionary: JMdict by EDRDG, CC BY-SA 4.0")
                }
            }
            .navigationTitle(lookup.result?.matched ?? lookup.text)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct EntryRow: View {
    let entry: DictionaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(entry.headword)
                    .font(.title.bold())
                if entry.reading != entry.headword {
                    Text(entry.reading)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                // The reading, so the voice can't pick the wrong one for the kanji.
                SpeakButton(text: entry.reading)
            }

            let labels = Self.labels(for: entry)
            if !labels.isEmpty {
                HStack(spacing: 6) {
                    ForEach(labels, id: \.self) { label in
                        Text(label)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.accentColor.opacity(0.15), in: Capsule())
                    }
                }
            }

            ForEach(Array(entry.meanings.enumerated()), id: \.offset) { index, meaning in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(index + 1).")
                        .foregroundStyle(.secondary)
                    Text(meaning)
                }
            }
        }
        .padding(.vertical, 4)
    }

    /// Friendly names for the most useful part-of-speech codes and usage notes.
    private static func labels(for entry: DictionaryEntry) -> [String] {
        let usage: [String: String] = [
            "col": "colloquial", "sl": "slang", "net-sl": "internet slang", "abbr": "abbreviation",
            "uk": "usually kana", "hon": "honorific", "hum": "humble", "pol": "polite",
            "vulg": "vulgar", "joc": "joking", "fam": "familiar", "male": "masculine",
            "fem": "feminine", "derog": "derogatory", "dated": "dated", "arch": "archaic",
            "rare": "rare", "on-mim": "onomatopoeia", "id": "idiom",
        ]
        var labels: [String] = []
        for pos in entry.partsOfSpeech {
            let label: String? = switch pos {
            case "v1": "ichidan verb"
            case _ where pos.hasPrefix("v5"): "godan verb"
            case "vs", "vs-i": "する verb"
            case "vk": "くる verb"
            case "adj-i", "adj-ix": "い-adjective"
            case "adj-na": "な-adjective"
            case "n": "noun"
            case "adv": "adverb"
            case "exp": "expression"
            case "int": "interjection"
            case "prt": "particle"
            default: nil
            }
            if let label, !labels.contains(label) {
                labels.append(label)
            }
        }
        labels = Array(labels.prefix(2))
        labels += entry.tags.compactMap { usage[$0] }.prefix(3)
        return labels
    }
}
