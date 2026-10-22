import Foundation

/// FSRS-5 spaced repetition scheduler (https://github.com/open-spaced-repetition).
/// Pure math with no storage: give it a card's memory state and a rating, get back the
/// new state and how long until the card is due again.
nonisolated enum FSRS {
    enum Rating: Int, CaseIterable {
        case again = 1, hard, good, easy

        var label: String {
            switch self {
            case .again: "Again"
            case .hard: "Hard"
            case .good: "Good"
            case .easy: "Easy"
            }
        }
    }

    struct MemoryState: Equatable {
        /// Days until recall probability drops to 90%.
        var stability: Double
        /// 1 (easy) to 10 (hard).
        var difficulty: Double
    }

    struct Result {
        let state: MemoryState
        /// Seconds until the card is due.
        let interval: TimeInterval
    }

    /// Default FSRS-5 parameters.
    static let w: [Double] = [
        0.40255, 1.18385, 3.173, 15.69105, 7.1949, 0.5345, 1.4604, 0.0046, 1.54575, 0.1192,
        1.01925, 1.9395, 0.11, 0.29605, 2.2698, 0.2315, 2.9898, 0.51655, 0.6621,
    ]
    /// Target recall probability when a card comes due. Higher means shorter intervals;
    /// 0.95 brings a new card rated Good back the next day instead of in 3 days.
    static let desiredRetention = 0.95
    static let maximumIntervalDays = 365.0
    /// A card rated Again comes back in the same session after this delay.
    static let relearnDelay: TimeInterval = 60

    private static let decay = -0.5
    private static let factor = 19.0 / 81.0
    private static let day: TimeInterval = 86_400

    /// - Parameters:
    ///   - state: nil for a card that has never been reviewed.
    ///   - elapsedDays: time since the last review, in days.
    static func next(state: MemoryState?, elapsedDays: Double, rating: Rating) -> Result {
        let g = Double(rating.rawValue)
        let newState: MemoryState

        if let state {
            let stability: Double
            if elapsedDays < 1 {
                stability = shortTermStability(state.stability, g)
            } else {
                let r = retrievability(elapsedDays: elapsedDays, stability: state.stability)
                stability = rating == .again
                    ? lapseStability(state.difficulty, state.stability, r)
                    : recallStability(state.difficulty, state.stability, r, rating)
            }
            newState = MemoryState(stability: stability, difficulty: nextDifficulty(state.difficulty, g))
        } else {
            newState = MemoryState(stability: w[rating.rawValue - 1], difficulty: clamp(initialDifficulty(g)))
        }

        return Result(state: newState, interval: interval(stability: newState.stability, rating: rating))
    }

    /// Probability of recalling a card `elapsedDays` after its last review.
    static func retrievability(elapsedDays: Double, stability: Double) -> Double {
        pow(1 + factor * elapsedDays / stability, decay)
    }

    private static func interval(stability: Double, rating: Rating) -> TimeInterval {
        if rating == .again { return relearnDelay }
        let days = stability / factor * (pow(desiredRetention, 1 / decay) - 1)
        return min(max(days.rounded(), 1), maximumIntervalDays) * day
    }

    private static func initialDifficulty(_ g: Double) -> Double {
        w[4] - exp(w[5] * (g - 1)) + 1
    }

    private static func nextDifficulty(_ d: Double, _ g: Double) -> Double {
        let delta = -w[6] * (g - 3)
        let damped = d + delta * (10 - d) / 9
        // Mean reversion toward the difficulty of a card first rated Easy.
        return clamp(w[7] * initialDifficulty(4) + (1 - w[7]) * damped)
    }

    private static func recallStability(_ d: Double, _ s: Double, _ r: Double, _ rating: Rating) -> Double {
        let hardPenalty = rating == .hard ? w[15] : 1
        let easyBonus = rating == .easy ? w[16] : 1
        return s * (1 + exp(w[8]) * (11 - d) * pow(s, -w[9]) * (exp(w[10] * (1 - r)) - 1) * hardPenalty * easyBonus)
    }

    private static func lapseStability(_ d: Double, _ s: Double, _ r: Double) -> Double {
        min(w[11] * pow(d, -w[12]) * (pow(s + 1, w[13]) - 1) * exp(w[14] * (1 - r)), s)
    }

    /// Reviews on the same day as the previous one.
    private static func shortTermStability(_ s: Double, _ g: Double) -> Double {
        s * exp(w[17] * (g - 3 + w[18]))
    }

    private static func clamp(_ d: Double) -> Double {
        min(max(d, 1), 10)
    }
}
