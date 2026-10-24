import SwiftUI

/// A lesson session, full screen: progress bar, one explainer or exercise at a time, and a
/// check / continue bar at the bottom.
struct SessionView: View {
    let session: LessonSession
    let onClose: () -> Void

    /// The answer the current exercise has so far; nil until there's something to check.
    @State private var pending: LessonSession.Answer?
    @State private var confirmingQuit = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    if session.isFinished || session.doneCount == 0 { onClose() } else { confirmingQuit = true }
                } label: {
                    Image(systemName: "xmark")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Close")
                ProgressView(value: session.progress)
                    .animation(.snappy, value: session.progress)
            }
            .padding()

            if session.isFinished {
                SessionSummary(session: session, onDone: onClose)
            } else if let step = session.current {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        StepLabel(step: step)
                        if let exercise = step.exercise {
                            ExerciseView(exercise: exercise, feedback: session.feedback, pending: $pending)
                        } else {
                            LessonIntroCard(lesson: step.lesson)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .id(step.id)
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomBar(step)
                }
            }
        }
        .confirmationDialog("Quit this lesson?", isPresented: $confirmingQuit, titleVisibility: .visible) {
            Button("Quit", role: .destructive, action: onClose)
        } message: {
            Text("Reviews you answered and lessons you finished are kept.")
        }
        .sensoryFeedback(trigger: session.feedback?.verdict) { _, verdict in
            switch verdict {
            case .right: .success
            case .wrong: .error
            default: nil
            }
        }
    }

    @ViewBuilder
    private func bottomBar(_ step: LessonSession.Step) -> some View {
        if let exercise = step.exercise, let feedback = session.feedback {
            FeedbackBar(exercise: exercise, feedback: feedback, onSettle: session.settle(isRight:)) {
                pending = nil
                withAnimation(.snappy) { session.next() }
            }
        } else {
            Button {
                if step.exercise == nil {
                    withAnimation(.snappy) { session.next() }
                } else if let pending {
                    Task { await session.check(pending) }
                }
            } label: {
                Group {
                    if session.isChecking {
                        ProgressView()
                    } else {
                        Text(step.exercise == nil ? "Got it" : "Check")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(step.exercise != nil && (pending == nil || session.isChecking))
            .padding()
            .background(.bar)
        }
    }
}

/// "New grammar", "Review" or "Weak spot" above the exercise.
private struct StepLabel: View {
    let step: LessonSession.Step

    private var text: (String, String, Color)? {
        switch step.purpose {
        case .new: step.exercise == nil ? ("New grammar", "sparkles", .purple) : nil
        case .review: ("Review · \(step.lesson.point.pattern)", "arrow.clockwise", .blue)
        case .practice: ("Practice · \(step.lesson.point.pattern)", "target", .orange)
        case .placement: nil
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            if let (label, icon, color) = text {
                Label(label, systemImage: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
            }
            if step.isRetry {
                Label("Try again", systemImage: "arrow.uturn.backward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
            }
        }
    }
}

// MARK: - Exercises

private struct ExerciseView: View {
    let exercise: Exercise
    let feedback: LessonSession.Feedback?
    @Binding var pending: LessonSession.Answer?

    var body: some View {
        switch exercise {
        case .choice(let sentence, let english, let options):
            ChoiceExercise(sentence: sentence, english: english, options: options, feedback: feedback, pending: $pending)
        case .build(let english, let chunks, let extras):
            BuildExercise(english: english, tiles: chunks.map(\.text) + extras, isLocked: feedback != nil, pending: $pending)
        case .translate(let english, _):
            TranslateExercise(english: english, isLocked: feedback != nil, pending: $pending)
        case .conjugate(let verb, let forms):
            ConjugateExercise(verb: verb, forms: forms, isLocked: feedback != nil, pending: $pending)
        }
    }
}

private struct Prompt: View {
    let title: String
    let english: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.bold())
            Text(english)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

/// Fill in the blank from three options.
private struct ChoiceExercise: View {
    @Environment(\.theme) private var theme
    let sentence: String
    let english: String
    let options: [String]
    let feedback: LessonSession.Feedback?
    @Binding var pending: LessonSession.Answer?

    @State private var shuffled: [String]
    @State private var picked: String?

    init(sentence: String, english: String, options: [String], feedback: LessonSession.Feedback?, pending: Binding<LessonSession.Answer?>) {
        self.sentence = sentence
        self.english = english
        self.options = options
        self.feedback = feedback
        _pending = pending
        _shuffled = State(initialValue: options.shuffled())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Prompt(title: "Fill in the blank", english: english)
            FuriganaText(sentence, onWordTap: { _ in })
                .font(.title2)
            VStack(spacing: 10) {
                ForEach(shuffled, id: \.self) { option in
                    Button {
                        picked = option
                        pending = .choice(option)
                    } label: {
                        Group {
                            if option == Exercise.nothing {
                                Text("(no particle)")
                            } else {
                                FuriganaText(option, onWordTap: { _ in })
                                    .allowsHitTesting(false)
                            }
                        }
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                        .background(background(option), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(border(option), lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .disabled(feedback != nil)
                }
            }
        }
    }

    private func border(_ option: String) -> Color {
        if feedback != nil {
            if option == options[0] { return .green }
            if option == picked { return .red }
            return Color(.separator)
        }
        return option == picked ? theme.accent : Color(.separator)
    }

    private func background(_ option: String) -> Color {
        border(option) == Color(.separator) ? Color(.secondarySystemBackground) : border(option).opacity(0.15)
    }
}

/// Tap tiles into order to build the sentence.
private struct BuildExercise: View {
    let english: String
    let tiles: [String]
    let isLocked: Bool
    @Binding var pending: LessonSession.Answer?

    /// Tile indices in the order they were tapped.
    @State private var placed: [Int] = []
    @State private var bank: [Int]

    init(english: String, tiles: [String], isLocked: Bool, pending: Binding<LessonSession.Answer?>) {
        self.english = english
        self.tiles = tiles
        self.isLocked = isLocked
        _pending = pending
        var order = Array(tiles.indices)
        // Don't start with the tiles already in order.
        while order.count > 1, order == Array(tiles.indices) { order.shuffle() }
        _bank = State(initialValue: order)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Prompt(title: "Build the sentence", english: english)

            FlowLayout(spacing: 8, lineSpacing: 10) {
                ForEach(placed, id: \.self) { index in
                    tile(index, isPlaced: true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .padding(10)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

            FlowLayout(spacing: 8, lineSpacing: 10) {
                ForEach(bank, id: \.self) { index in
                    if placed.contains(index) {
                        // Keeps the tile's spot so the others don't jump around.
                        tile(index, isPlaced: true).hidden()
                            .overlay(RoundedRectangle(cornerRadius: 10).fill(Color(.tertiarySystemFill)))
                    } else {
                        tile(index, isPlaced: false)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .animation(.snappy(duration: 0.2), value: placed)
    }

    private func tile(_ index: Int, isPlaced: Bool) -> some View {
        Button {
            if isPlaced {
                placed.removeAll { $0 == index }
            } else {
                placed.append(index)
            }
            pending = placed.isEmpty ? nil : .tiles(placed.map { tiles[$0] })
        } label: {
            FuriganaText(tiles[index], onWordTap: { _ in })
                .allowsHitTesting(false)
                .font(.title3)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .fixedSize()
    }
}

/// Type the Japanese for an English sentence.
private struct TranslateExercise: View {
    let english: String
    let isLocked: Bool
    @Binding var pending: LessonSession.Answer?

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Say it in Japanese")
                .font(.title3.bold())
            Text(english)
                .font(.title2.weight(.medium))
            TextField("日本語で…", text: $text, axis: .vertical)
                .font(.title3)
                .lineLimit(2...5)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                .disabled(isLocked)
                .onChange(of: text) {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    pending = trimmed.isEmpty ? nil : .typed(trimmed)
                }
            Text("Kanji or kana both work. Typed answers that don't match exactly are checked by こと.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear { isFocused = true }
    }
}

/// Type a verb in the asked-for form.
private struct ConjugateExercise: View {
    @Environment(\.theme) private var theme
    let verb: Verb
    let forms: [VerbForm]
    let isLocked: Bool
    @Binding var pending: LessonSession.Answer?

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Conjugate")
                .font(.title3.bold())

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 8) {
                    FuriganaText(verb.kanji, onWordTap: { _ in })
                        .font(.largeTitle)
                    SpeakButton(text: verb.kanji, font: .body)
                }
                Text(verb.english)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            FlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(Array(forms.enumerated()), id: \.offset) { index, form in
                    if index > 0 {
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(height: 30)
                    }
                    Text(form.label)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.accent.opacity(0.15), in: Capsule())
                }
            }

            TextField("活用形…", text: $text)
                .font(.title2)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                .disabled(isLocked)
                .onChange(of: text) {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    pending = trimmed.isEmpty ? nil : .typed(trimmed)
                }
            Text("Kanji or kana both work. Checked on your phone, no connection needed.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear { isFocused = true }
    }
}

// MARK: - Feedback

/// Right or wrong, the answer with furigana and audio, its structure, and Continue.
private struct FeedbackBar: View {
    let exercise: Exercise
    let feedback: LessonSession.Feedback
    let onSettle: (Bool) -> Void
    let onContinue: () -> Void

    private var color: Color {
        switch feedback.verdict {
        case .right: .green
        case .wrong: .red
        case .unsure: .orange
        }
    }

    private var title: String {
        switch feedback.verdict {
        case .right: "正解！"
        case .wrong: "Not quite"
        case .unsure: "Check it yourself"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: feedback.verdict == .right ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title3.bold())
                .foregroundStyle(color)

            if exercise.isTyped, feedback.verdict != .right {
                Text("You wrote: \(feedback.given)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .center, spacing: 8) {
                FuriganaText(exercise.answerSentence, onWordTap: { _ in })
                Spacer()
                SpeakButton(text: exercise.answerSentence, font: .body)
            }

            if let structure = exercise.structure {
                StructureView(chunks: structure)
            }

            if let note = feedback.note {
                Text(note)
                    .font(.subheadline)
            }

            if feedback.verdict == .unsure {
                HStack(spacing: 10) {
                    Button("I got it right") { onSettle(true) }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    Button("I got it wrong") { onSettle(false) }
                        .buttonStyle(.bordered)
                        .tint(.red)
                }
                .frame(maxWidth: .infinity)
            } else {
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(color)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.12))
        .background(.bar)
    }
}

// MARK: - Summary

private struct SessionSummary: View {
    let session: LessonSession
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("お疲れさま！")
                .font(.largeTitle.bold())
            if session.answered > 0 {
                Text("\(session.correct) of \(session.answered) right on the first try")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                list("New in your grammar deck", session.learned, color: .purple)
                list("Tested out", session.testedOut, color: .green)
                list("Worth a lesson", session.toLearn, color: .orange)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            Spacer()
            Button(action: onDone) {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }

    @ViewBuilder
    private func list(_ title: String, _ lessons: [CourseLesson], color: Color) -> some View {
        if !lessons.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
                    .textCase(.uppercase)
                ForEach(lessons) { lesson in
                    HStack(alignment: .firstTextBaseline) {
                        Text(lesson.point.pattern)
                            .font(.headline)
                        Text(lesson.point.meaning)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}
