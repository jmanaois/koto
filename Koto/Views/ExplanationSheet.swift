import SwiftUI

/// English translation and phrase-by-phrase breakdown of one of こと's messages.
/// Fetched the first time it's opened, then saved with the message.
struct ExplanationSheet: View {
    let message: ChatMessage
    let load: () async throws -> Void

    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    FuriganaText(message.text, onWordTap: { _ in })
                        .padding(.vertical, 4)
                }

                if let explanation = message.explanation, explanation.isComplete {
                    Section("Translation") {
                        Text(explanation.translation)
                    }
                    if let structure = explanation.structure, !structure.isEmpty {
                        Section {
                            StructureView(chunks: structure)
                                .padding(.vertical, 4)
                        } header: {
                            Text("Structure")
                        } footer: {
                            Text("Each colored piece is one part of the sentence, with its particle.")
                        }
                    }
                    if !explanation.breakdown.isEmpty {
                        Section("Breakdown") {
                            ForEach(explanation.breakdown, id: \.self) { part in
                                VStack(alignment: .leading, spacing: 4) {
                                    FuriganaText(part.phrase, onWordTap: { _ in })
                                        .font(.headline)
                                    Text(part.explanation)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                } else if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                        Button("Try again") {
                            Task { await run() }
                        }
                    }
                } else {
                    Section {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Translating…")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Translation")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await run() }
    }

    private func run() async {
        errorMessage = nil
        do {
            try await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// The sentence split into color-coded parts (topic, object, verb...) with a legend of the roles used.
private struct StructureView: View {
    let chunks: [MessageExplanation.Chunk]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FlowLayout(spacing: 4, lineSpacing: 8) {
                ForEach(Array(chunks.enumerated()), id: \.offset) { _, chunk in
                    if chunk.role == .other {
                        Text(chunk.text)
                            .font(.title3)
                            .padding(.vertical, 4)
                    } else {
                        VStack(spacing: 2) {
                            Text(chunk.text)
                                .font(.title3)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Self.color(chunk.role).opacity(0.25), in: RoundedRectangle(cornerRadius: 6))
                                .overlay(alignment: .bottom) {
                                    Rectangle()
                                        .fill(Self.color(chunk.role))
                                        .frame(height: 2)
                                }
                            Text(Self.shortLabel(chunk.role))
                                .font(.caption2)
                                .foregroundStyle(Self.color(chunk.role))
                        }
                        .fixedSize()
                    }
                }
            }

            let roles = MessageExplanation.Chunk.Role.allCases.filter { role in
                role != .other && chunks.contains { $0.role == role }
            }
            FlowLayout(spacing: 10, lineSpacing: 4) {
                ForEach(roles, id: \.self) { role in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Self.color(role))
                            .frame(width: 8, height: 8)
                        Text(role.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .fixedSize()
                }
            }
        }
    }

    private static func shortLabel(_ role: MessageExplanation.Chunk.Role) -> String {
        switch role {
        case .topic: "topic"
        case .subject: "subject"
        case .object: "object"
        case .time: "time"
        case .place: "place"
        case .target: "target"
        case .verb: "verb"
        case .description: "describes"
        case .ending: "ending"
        case .connector: "connector"
        case .other: ""
        }
    }

    private static func color(_ role: MessageExplanation.Chunk.Role) -> Color {
        switch role {
        case .topic: .blue
        case .subject: .indigo
        case .object: .orange
        case .time: .teal
        case .place: .mint
        case .target: .cyan
        case .verb: .red
        case .description: .purple
        case .ending: .pink
        case .connector: .brown
        case .other: .gray
        }
    }
}
