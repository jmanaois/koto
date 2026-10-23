import SwiftData
import SwiftUI

/// Words, grammar and common mistakes, behind the book button in the chat.
struct StudyView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case words = "Words"
        case grammar = "Grammar"
        case mistakes = "Mistakes"

        var id: String { rawValue }
    }

    @State private var tab: Tab = .words

    var body: some View {
        Group {
            switch tab {
            case .words: VocabDeckView()
            case .grammar: GrammarDeckView()
            case .mistakes: MistakesView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Study", selection: $tab) {
                    ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)
            }
        }
    }
}

// MARK: - Grammar deck

struct GrammarDeckView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SavedGrammar.addedAt, order: .reverse) private var patterns: [SavedGrammar]
    @State private var selected: SavedGrammar?

    private var dueCount: Int {
        patterns.filter { $0.dueAt <= .now }.count
    }

    var body: some View {
        List {
            if !patterns.isEmpty {
                Section {
                    ReviewRow<SavedGrammar>(dueCount: dueCount)
                }
            }

            Section {
                ForEach(patterns) { grammar in
                    Button {
                        selected = grammar
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(grammar.pattern)
                                    .font(.headline)
                                if let base = grammar.base {
                                    Text("from \(base)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                DueLabel(dueAt: grammar.dueAt)
                            }
                            Text(grammar.meaning)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .foregroundStyle(.primary)
                }
                .onDelete { offsets in
                    for index in offsets {
                        context.delete(patterns[index])
                    }
                }
            }
        }
        .overlay {
            if patterns.isEmpty {
                ContentUnavailableView(
                    "No grammar yet",
                    systemImage: "puzzlepiece.extension",
                    description: Text("Tap a grammar chip under こと's messages to save the pattern here.")
                )
            }
        }
        .sheet(item: $selected) { grammar in
            GrammarDetailSheet(point: grammar.grammarPoint)
                .presentationDetents([.medium, .large])
        }
    }
}

/// A grammar pattern: what it means, where it comes from, examples, and Add to my grammar.
struct GrammarDetailSheet: View {
    let point: GrammarPoint
    var example: ExampleSentence?

    @Environment(\.modelContext) private var context
    @Query private var saved: [SavedGrammar]

    private var savedGrammar: SavedGrammar? {
        saved.first { $0.pattern == point.pattern }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(point.pattern)
                            .font(.largeTitle.bold())
                        if let base = point.base {
                            Text("Casual form of \(base)")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.tint)
                        }
                        Text(point.meaning)
                            .font(.title3)
                        Text(point.note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                if !point.examples.isEmpty {
                    Section("Examples") {
                        ForEach(point.examples, id: \.self) { example in
                            HStack(alignment: .center, spacing: 8) {
                                VStack(alignment: .leading, spacing: 4) {
                                    FuriganaText(
                                        example.japanese,
                                        highlighting: point.pattern.replacingOccurrences(of: "〜", with: ""),
                                        onWordTap: { _ in }
                                    )
                                    Text(example.english)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                SpeakButton(text: example.japanese, font: .body)
                            }
                        }
                    }
                }

                Section {
                    Group {
                        if let savedGrammar {
                            VStack(spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("In my grammar")
                                }
                                .foregroundStyle(.green)
                                .font(.headline)
                                Button("Remove", role: .destructive) {
                                    context.delete(savedGrammar)
                                }
                                .font(.footnote)
                                .buttonStyle(.borderless)
                            }
                        } else {
                            Button {
                                context.insert(SavedGrammar(point, example: example))
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                    Text("Add to my grammar")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Grammar")
            .navigationBarTitleDisplayMode(.inline)
            .sensoryFeedback(.success, trigger: savedGrammar != nil) { _, isSaved in isSaved }
        }
    }
}

// MARK: - Mistakes

/// The grammar points こと has corrected most, so the user can see what to work on.
struct MistakesView: View {
    @Query(sort: \MistakeRecord.date, order: .reverse) private var records: [MistakeRecord]

    private struct Summary: Identifiable {
        let point: String
        let records: [MistakeRecord]
        var id: String { point }
        var recentCount: Int {
            let weekAgo = Date.now.addingTimeInterval(-7 * 86_400)
            return records.filter { $0.date >= weekAgo }.count
        }
    }

    private var summaries: [Summary] {
        Dictionary(grouping: records, by: \.point)
            .map { Summary(point: $0.key, records: $0.value) }
            .sorted { ($0.records.count, $0.records[0].date) > ($1.records.count, $1.records[0].date) }
    }

    var body: some View {
        List {
            if !records.isEmpty {
                Section {
                } footer: {
                    Text("Grammar points こと has corrected, most frequent first. こと looks for chances to practice your top ones in conversation.")
                }
            }
            ForEach(summaries) { summary in
                NavigationLink {
                    MistakeListView(point: summary.point, records: summary.records)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(summary.point)
                                .font(.headline)
                            Spacer()
                            Text("\(summary.records.count)×")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(.orange)
                        }
                        let latest = summary.records[0]
                        HStack(spacing: 4) {
                            Text(latest.original)
                                .strikethrough(latest.suggested != nil)
                            if let suggested = latest.suggested {
                                Image(systemName: "arrow.right")
                                Text(suggested)
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        if summary.recentCount > 0 {
                            Text("\(summary.recentCount) this week")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .overlay {
            if records.isEmpty {
                ContentUnavailableView(
                    "No mistakes yet",
                    systemImage: "checkmark.seal",
                    description: Text("Grammar corrections from こと show up here, grouped by grammar point.")
                )
            }
        }
    }
}

private struct MistakeListView: View {
    let point: String
    let records: [MistakeRecord]

    var body: some View {
        List(records) { record in
            VStack(alignment: .leading, spacing: 6) {
                Text(record.original)
                    .strikethrough(record.suggested != nil)
                    .foregroundStyle(.secondary)
                if let suggested = record.suggested {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.turn.down.right")
                            .foregroundStyle(.tint)
                        Text(suggested)
                            .fontWeight(.semibold)
                    }
                }
                Text(record.explanation)
                    .font(.footnote)
                Text(record.date, format: .dateTime.month().day().hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 2)
        }
        .navigationTitle(point)
        .navigationBarTitleDisplayMode(.inline)
    }
}
