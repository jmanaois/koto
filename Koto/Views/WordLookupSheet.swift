import SwiftUI

/// A word the user tapped in a message, and what the dictionary found for it.
struct WordLookup: Identifiable {
    let id = UUID()
    /// Text from the tapped word onward, e.g. 食べましたか.
    let text: String
    let result: LookupResult?

    init(text: String) {
        self.text = text
        result = JapaneseDictionary.shared.lookup(text)
    }
}

struct WordLookupSheet: View {
    let lookup: WordLookup

    var body: some View {
        NavigationStack {
            List {
                if let result = lookup.result {
                    ForEach(result.entries) { entry in
                        Section {
                            EntryRow(entry: entry)
                            SaveWordButton(item: entry.vocabItem)
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
