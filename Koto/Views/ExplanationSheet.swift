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

                if let explanation = message.explanation {
                    Section("Translation") {
                        Text(explanation.translation)
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
