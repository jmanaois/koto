import Foundation
import Observation
import SwiftData

/// What today's lesson holds: due grammar to review, weak points to practice, and new lessons.
struct DailyPlan {
    var reviews: [CourseLesson] = []
    var practice: [CourseLesson] = []
    var new: [CourseLesson] = []

    var isEmpty: Bool { reviews.isEmpty && practice.isEmpty && new.isEmpty }

    static let newPerDay = 2
    static let maxReviews = 15

    /// Due course grammar (weak points first), up to two weak points that aren't due, and the next
    /// new lessons, up to `newPerDay` a day.
    static func today(context: ModelContext, now: Date = .now) -> DailyPlan {
        let progress = (try? context.fetch(FetchDescriptor<LessonProgress>())) ?? []
        let done = Set(progress.map(\.lessonID))
        let learnedToday = progress.filter { !$0.testedOut && Calendar.current.isDate($0.completedAt, inSameDayAs: now) }.count

        let weak = weakPoints(context: context)
        func isWeak(_ lesson: CourseLesson) -> Bool { weak.contains { lesson.matches(mistakePoint: $0) } }

        let grammar = (try? context.fetch(FetchDescriptor<SavedGrammar>())) ?? []
        let due = grammar
            .filter { $0.dueAt <= now }
            .compactMap { card in Curriculum.lesson(pattern: card.pattern).map { (lesson: $0, dueAt: card.dueAt) } }
            .sorted { (isWeak($0.lesson) ? 0 : 1, $0.dueAt) < (isWeak($1.lesson) ? 0 : 1, $1.dueAt) }
            .map(\.lesson)

        // Weak spots are part of the day's first lesson only, and not for lessons just learned,
        // so finishing the day's lesson leaves nothing to do until reviews come due.
        let studiedToday = ((try? context.fetch(FetchDescriptor<StudyDay>())) ?? []).contains {
            Calendar.current.isDate($0.day, inSameDayAs: now)
        }
        let learnedTodayIDs = Set(progress.filter { Calendar.current.isDate($0.completedAt, inSameDayAs: now) }.map(\.lessonID))

        var plan = DailyPlan()
        plan.reviews = Array(due.prefix(maxReviews))
        if !studiedToday {
            plan.practice = Array(
                Curriculum.lessons.filter {
                    done.contains($0.id) && !learnedTodayIDs.contains($0.id) && !plan.reviews.contains($0) && isWeak($0)
                }.prefix(2)
            )
        }
        plan.new = Array(Curriculum.lessons.filter { !done.contains($0.id) }.prefix(max(0, newPerDay - learnedToday)))
        return plan
    }

    /// One more new lesson, after today's are done.
    static func extra(context: ModelContext) -> DailyPlan {
        let done = Set(((try? context.fetch(FetchDescriptor<LessonProgress>())) ?? []).map(\.lessonID))
        return DailyPlan(new: Array(Curriculum.lessons.filter { !done.contains($0.id) }.prefix(1)))
    }

    /// Grammar points こと corrected most, most frequent first.
    static func weakPoints(context: ModelContext) -> [String] {
        let records = (try? context.fetch(FetchDescriptor<MistakeRecord>())) ?? []
        return Dictionary(grouping: records, by: \.point)
            .sorted { $0.value.count > $1.value.count }
            .prefix(5)
            .map(\.key)
    }
}

/// One run through course exercises: today's lesson, a single lesson, or a unit's placement check.
@Observable
final class LessonSession {
    enum Kind: Equatable {
        case daily
        case lesson
        case placement(unit: Int)
        /// Conjugation practice on random verbs; nothing is learned or rated.
        case drill
    }

    struct Step: Identifiable {
        enum Purpose {
            /// A lesson being learned now; finishing its steps completes it.
            case new
            /// A due grammar card; the first try rates it.
            case review
            /// Extra practice, no rating.
            case practice
            case placement
        }

        let id = UUID()
        let lesson: CourseLesson
        /// nil for the lesson's explainer card.
        let exercise: Exercise?
        let purpose: Purpose
        var isRetry = false
    }

    enum Answer {
        case choice(String)
        case tiles([String])
        case typed(String)
    }

    struct Feedback {
        enum Verdict {
            case right, wrong
            /// The typed answer couldn't be checked; the user compares it with the answer.
            case unsure
        }

        var verdict: Verdict
        var given: String
        var note: String?
    }

    let kind: Kind
    private(set) var queue: [Step]
    private(set) var doneCount = 0
    private(set) var feedback: Feedback?
    private(set) var isChecking = false
    private(set) var answered = 0
    private(set) var correct = 0
    private(set) var isFinished = false
    /// Lessons finished in this session.
    private(set) var learned: [CourseLesson] = []
    /// Placement results.
    private(set) var testedOut: [CourseLesson] = []
    private(set) var toLearn: [CourseLesson] = []

    /// Wrong answers per lesson id.
    private var mistakes: [String: Int] = [:]
    private let context: ModelContext
    private let service: ChatService

    var current: Step? { queue.first }
    var progress: Double { Double(doneCount) / Double(max(1, doneCount + queue.count)) }

    init(daily plan: DailyPlan, context: ModelContext, service: ChatService) {
        kind = .daily
        self.context = context
        self.service = service
        let warmUp = (plan.reviews.map { ($0, Step.Purpose.review) } + plan.practice.map { ($0, .practice) })
            .shuffled()
            .map { Step(lesson: $0.0, exercise: $0.0.exercises.randomElement(), purpose: $0.1) }
        queue = warmUp + plan.new.flatMap { Self.steps(learning: $0, purpose: .new) }
    }

    /// Learns `lesson`, or practices it again if it's already done.
    init(lesson: CourseLesson, isDone: Bool, context: ModelContext, service: ChatService) {
        kind = .lesson
        self.context = context
        self.service = service
        queue = Self.steps(learning: lesson, purpose: isDone ? .practice : .new)
    }

    /// Two questions on each lesson of the unit not done yet. Lessons with both right are skipped.
    init(placement unit: CourseUnit, done: Set<String>, context: ModelContext, service: ChatService) {
        kind = .placement(unit: unit.id)
        self.context = context
        self.service = service
        queue = unit.lessons
            .filter { !done.contains($0.id) }
            .flatMap { lesson in
                lesson.exercises.filter(\.isOffline).shuffled().prefix(2)
                    .map { Step(lesson: lesson, exercise: $0, purpose: .placement) }
            }
            .shuffled()
    }

    /// `count` random verbs in random `forms`. With `chains`, some questions stack a derived form
    /// (potential, passive…) with an ending: 呼ばれなかった.
    init(drill forms: [VerbForm], chains: Bool, count: Int, context: ModelContext, service: ChatService) {
        kind = .drill
        self.context = context
        self.service = service
        let derived = forms.filter(\.isDerived)
        var seen: Set<Exercise> = []
        var steps: [Step] = []
        while steps.count < count, !forms.isEmpty, seen.count < count * 3 {
            var chain = [forms.randomElement()!]
            if chains, !derived.isEmpty, Bool.random() {
                chain = [derived.randomElement()!, VerbForm.endings.randomElement()!]
            }
            guard let verb = Verb.pool.filter({ verb in chain.allSatisfy(verb.drills) }).randomElement() else { continue }
            let exercise = Exercise.conjugate(verb: verb, forms: chain)
            guard seen.insert(exercise).inserted else { continue }
            steps.append(Step(lesson: ConjugationCourse.lesson(drilling: chain), exercise: exercise, purpose: .practice))
        }
        queue = steps
    }

    private static func steps(learning lesson: CourseLesson, purpose: Step.Purpose) -> [Step] {
        [Step(lesson: lesson, exercise: nil, purpose: purpose)]
            + lesson.exercises.map { Step(lesson: lesson, exercise: $0, purpose: purpose) }
    }

    // MARK: - Answering

    func check(_ answer: Answer) async {
        guard let step = current, let exercise = step.exercise, feedback == nil, !isChecking else { return }
        switch (exercise, answer) {
        case (.choice(let sentence, _, let options), .choice(let picked)):
            let given = sentence.replacingOccurrences(of: Exercise.blank, with: picked == Exercise.nothing ? "" : picked)
            finishCheck(Feedback(verdict: picked == options[0] ? .right : .wrong, given: given))
        case (.build(_, let chunks, _), .tiles(let tiles)):
            let given = tiles.joined()
            finishCheck(Feedback(verdict: given == chunks.map(\.text).joined() ? .right : .wrong, given: given))
        case (.conjugate(let verb, let forms), .typed(let text)):
            let given = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let isRight = Conjugator.matches(given, Conjugator.conjugate(verb, forms))
            finishCheck(Feedback(verdict: isRight ? .right : .wrong, given: given, note: Conjugator.rule(verb, forms)))
        case (.translate(let english, let answers), .typed(let text)):
            let given = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let typed = Exercise.comparable(given)
            if typed.isEmpty {
                finishCheck(Feedback(verdict: .wrong, given: given))
            } else if answers.contains(where: { Exercise.comparable($0) == typed }) {
                finishCheck(Feedback(verdict: .right, given: given))
            } else {
                isChecking = true
                do {
                    let grade = try await service.gradeTranslation(
                        given, english: english, expected: answers, grammar: step.lesson.point
                    )
                    finishCheck(Feedback(verdict: grade.correct ? .right : .wrong, given: given, note: grade.feedback))
                } catch {
                    finishCheck(Feedback(
                        verdict: .unsure, given: given,
                        note: "Couldn't check it (\(error.localizedDescription)). Compare with the answer below."
                    ))
                }
                isChecking = false
            }
        default:
            return
        }
    }

    /// The user's call on an answer that couldn't be checked.
    func settle(isRight: Bool) {
        guard var feedback, feedback.verdict == .unsure else { return }
        feedback.verdict = isRight ? .right : .wrong
        finishCheck(feedback)
    }

    private func finishCheck(_ feedback: Feedback) {
        self.feedback = feedback
        guard feedback.verdict != .unsure, let step = current, let exercise = step.exercise else { return }
        let isRight = feedback.verdict == .right
        if !step.isRetry {
            answered += 1
            if isRight { correct += 1 }
        }

        if step.purpose == .review, !step.isRetry, let card = savedGrammar(step.lesson) {
            card.review(isRight ? .good : .again)
        }
        guard !isRight else { return }
        mistakes[step.lesson.id, default: 0] += 1
        if step.purpose != .placement {
            // Try it again at the end, like a card rated Again.
            queue.append(Step(lesson: step.lesson, exercise: exercise, purpose: step.purpose, isRetry: true))
            let correction = Correction(
                original: feedback.given, suggested: exercise.answerSentence, type: .grammar,
                explanation: "Course exercise: \(exercise.english)"
            )
            context.insert(MistakeRecord(point: step.lesson.point.pattern, correction: correction))
        }
    }

    /// Moves past the explainer card or the answered exercise.
    func next() {
        guard let step = queue.first, step.exercise == nil || (feedback != nil && feedback?.verdict != .unsure) else { return }
        queue.removeFirst()
        doneCount += 1
        feedback = nil
        if step.purpose == .new, !queue.contains(where: { $0.lesson == step.lesson }) {
            complete(step.lesson)
        }
        if queue.isEmpty { finish() }
    }

    // MARK: - Progress

    private func savedGrammar(_ lesson: CourseLesson) -> SavedGrammar? {
        let pattern = lesson.point.pattern
        return try? context.fetch(FetchDescriptor<SavedGrammar>(predicate: #Predicate { $0.pattern == pattern })).first
    }

    /// Marks the lesson done and adds its grammar to the deck, first review based on how it went.
    private func complete(_ lesson: CourseLesson, testedOut: Bool = false) {
        let id = lesson.id
        let existing = try? context.fetch(FetchDescriptor<LessonProgress>(predicate: #Predicate { $0.lessonID == id })).first
        if existing == nil {
            context.insert(LessonProgress(lessonID: id, testedOut: testedOut))
        }
        if savedGrammar(lesson) == nil {
            let card = SavedGrammar(lesson.point)
            context.insert(card)
            card.review(testedOut || mistakes[id, default: 0] == 0 ? .good : .hard)
        }
        if testedOut {
            self.testedOut.append(lesson)
        } else {
            learned.append(lesson)
        }
    }

    private func finish() {
        isFinished = true
        if case .placement(let unitID) = kind, let unit = Curriculum.units.first(where: { $0.id == unitID }) {
            let done = Set(((try? context.fetch(FetchDescriptor<LessonProgress>())) ?? []).map(\.lessonID))
            for lesson in unit.lessons where !done.contains(lesson.id) {
                if mistakes[lesson.id, default: 0] == 0 {
                    complete(lesson, testedOut: true)
                } else {
                    toLearn.append(lesson)
                }
            }
        }
        if answered > 0 {
            let today = Calendar.current.startOfDay(for: .now)
            let day = (try? context.fetch(FetchDescriptor<StudyDay>(predicate: #Predicate { $0.day == today })).first)
                ?? { let day = StudyDay(day: today); context.insert(day); return day }()
            day.exercises += answered
            day.correct += correct
        }
        try? context.save()
        Reminders.reschedule(context: context)
    }
}
