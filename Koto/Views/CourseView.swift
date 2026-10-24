import SwiftData
import SwiftUI

/// The Learn tab: streak, today's lesson, and the course path unit by unit.
struct CourseView: View {
    let service: ChatService

    @Environment(\.modelContext) private var context
    @Query private var progress: [LessonProgress]
    @Query private var studyDays: [StudyDay]
    // Not read directly; keeps today's plan current as cards are reviewed and mistakes logged.
    @Query private var grammar: [SavedGrammar]
    @Query private var mistakes: [MistakeRecord]
    @State private var session: LessonSession?

    private var done: Set<String> { Set(progress.map(\.lessonID)) }
    private var nextLesson: CourseLesson? { Curriculum.lessons.first { !done.contains($0.id) } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TodayCard(
                        plan: DailyPlan.today(context: context),
                        streak: Streak.count(studyDays.map(\.day)),
                        doneToday: Streak.didStudyToday(studyDays.map(\.day)),
                        lessonsDone: done.count,
                        hasMoreLessons: nextLesson != nil,
                        onStart: { session = LessonSession(daily: DailyPlan.today(context: context), context: context, service: service) },
                        onExtra: { session = LessonSession(daily: DailyPlan.extra(context: context), context: context, service: service) }
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Section {
                    NavigationLink {
                        ConjugationDrillSetup { forms, chains, count in
                            session = LessonSession(drill: forms, chains: chains, count: count, context: context, service: service)
                        }
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Conjugation drill")
                                    .font(.headline)
                                Text("Type verb forms on random verbs, from ない to causative-passive")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(.tint)
                        }
                    }
                }

                ForEach(Curriculum.units) { unit in
                    unitSection(unit)
                }
            }
            .navigationTitle("Learn")
            .navigationDestination(for: CourseLesson.self) { lesson in
                LessonDetailView(lesson: lesson, isDone: done.contains(lesson.id)) {
                    session = LessonSession(lesson: lesson, isDone: done.contains(lesson.id), context: context, service: service)
                }
            }
            .fullScreenCover(item: $session) { session in
                SessionView(session: session) { self.session = nil }
            }
        }
    }

    private func unitSection(_ unit: CourseUnit) -> some View {
        let finished = unit.lessons.filter { done.contains($0.id) }.count
        return Section {
            ForEach(unit.lessons) { lesson in
                NavigationLink(value: lesson) {
                    LessonRow(lesson: lesson, record: progress.first { $0.lessonID == lesson.id }, isNext: lesson == nextLesson)
                }
            }
            if finished < unit.lessons.count {
                Button {
                    session = LessonSession(placement: unit, done: done, context: context, service: service)
                } label: {
                    Label("Already know this? Test out", systemImage: "forward.fill")
                        .font(.subheadline)
                }
            }
        } header: {
            HStack {
                Text("\(unit.level) · Unit \(unit.id) · \(unit.title)")
                Spacer()
                Text("\(finished)/\(unit.lessons.count)")
                    .monospacedDigit()
            }
        } footer: {
            Text(unit.summary)
        }
    }
}

extension LessonSession: Identifiable {}

/// Picks the forms, chaining and length for a conjugation drill.
private struct ConjugationDrillSetup: View {
    let onStart: ([VerbForm], Bool, Int) -> Void

    @AppStorage("drillForms") private var storedForms = "negative,past,te,potential,volitional"
    @AppStorage("drillChains") private var chains = false
    @AppStorage("drillCount") private var count = 20

    private var forms: [VerbForm] {
        let names = Set(storedForms.split(separator: ",").map(String.init))
        return VerbForm.allCases.filter { names.contains($0.rawValue) }
    }

    private func binding(_ form: VerbForm) -> Binding<Bool> {
        Binding {
            forms.contains(form)
        } set: { isOn in
            let updated = VerbForm.allCases.filter { $0 == form ? isOn : forms.contains($0) }
            storedForms = updated.map(\.rawValue).joined(separator: ",")
        }
    }

    var body: some View {
        Form {
            Section("Basic forms") {
                ForEach(VerbForm.basics) { form in
                    Toggle(form.label, isOn: binding(form))
                }
            }
            Section("N4 forms") {
                ForEach(VerbForm.advanced) { form in
                    Toggle(form.label, isOn: binding(form))
                }
            }
            Section {
                Toggle("Chain forms", isOn: $chains)
                    .disabled(!forms.contains(where: \.isDerived))
                Stepper("\(count) questions", value: $count, in: 10...50, step: 5)
                    .monospacedDigit()
            } footer: {
                Text("Chaining stacks a potential, passive or causative form with an ending, like 呼ばれなかった or 休ませて.")
            }
        }
        .navigationTitle("Conjugation drill")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                onStart(forms, chains, count)
            } label: {
                Text("Start drill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(forms.isEmpty)
            .padding()
            .background(.bar)
        }
    }
}

/// Streak, what today's lesson holds, and the button to start it.
private struct TodayCard: View {
    let plan: DailyPlan
    let streak: Int
    let doneToday: Bool
    let lessonsDone: Int
    let hasMoreLessons: Bool
    let onStart: () -> Void
    let onExtra: () -> Void

    private var summary: String {
        var parts: [String] = []
        if !plan.reviews.isEmpty { parts.append("\(plan.reviews.count) review\(plan.reviews.count == 1 ? "" : "s")") }
        if !plan.practice.isEmpty { parts.append("\(plan.practice.count) weak spot\(plan.practice.count == 1 ? "" : "s")") }
        if !plan.new.isEmpty { parts.append("\(plan.new.count) new") }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Label {
                    Text("\(streak) day\(streak == 1 ? "" : "s")")
                        .font(.title2.bold())
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(streak > 0 && doneToday ? .orange : .secondary)
                }
                Spacer()
                Text("\(lessonsDone)/\(Curriculum.lessons.count) lessons")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            if plan.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(doneToday ? "Done for today 🎉" : "Nothing due right now")
                        .font(.headline)
                    Text(hasMoreLessons ? "Reviews come back as they're due. Want to keep going?" : "You've finished every lesson. Reviews come back as they're due.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if hasMoreLessons {
                    Button(action: onExtra) {
                        Text("Learn one more lesson")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Button(action: onStart) {
                    VStack(spacing: 2) {
                        Text(doneToday ? "Keep going" : "Start today's lesson")
                            .font(.headline)
                        Text(summary)
                            .font(.caption)
                            .opacity(0.85)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct LessonRow: View {
    let lesson: CourseLesson
    let record: LessonProgress?
    let isNext: Bool

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if record != nil {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                } else if isNext {
                    Image(systemName: "play.circle.fill").foregroundStyle(.tint)
                } else {
                    Image(systemName: "circle").foregroundStyle(.tertiary)
                }
            }
            .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(lesson.point.pattern)
                    .font(.headline)
                Text(lesson.point.meaning)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if record?.testedOut == true {
                    Text("Tested out")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

/// A lesson's explainer, with a button to learn or practice it.
private struct LessonDetailView: View {
    let lesson: CourseLesson
    let isDone: Bool
    let onStart: () -> Void

    var body: some View {
        ScrollView {
            LessonIntroCard(lesson: lesson)
                .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onStart) {
                Text(isDone ? "Practice again" : "Learn this lesson")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .background(.bar)
        }
        .navigationTitle(lesson.point.pattern)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// What a grammar point means, how it's built, notes and examples.
struct LessonIntroCard: View {
    @Environment(\.theme) private var theme
    let lesson: CourseLesson

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(lesson.point.pattern)
                    .font(.largeTitle.bold())
                Text(lesson.point.meaning)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("How to make it")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(lesson.formation)
                    .font(.headline)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            Text(lesson.point.note)
                .font(.body)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(lesson.point.examples, id: \.self) { example in
                    HStack(alignment: .center, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            FuriganaText(
                                example.japanese,
                                highlighting: lesson.point.pattern.replacingOccurrences(of: "〜", with: ""),
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
            .padding(12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
