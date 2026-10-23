import Foundation
import SwiftData
import UserNotifications

/// A daily notification for the grammar course, skipped on days the lesson is already done.
enum Reminders {
    private static let idPrefix = "daily-lesson-"
    /// Notifications are scheduled this many days ahead and refreshed whenever the app opens.
    private static let daysAhead = 7

    /// Asks for permission the first time; returns whether notifications are allowed.
    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Replaces the scheduled reminders to match the setting, today's progress and the streak.
    static func reschedule(context: ModelContext) {
        let center = UNUserNotificationCenter.current()
        let ids = (0..<daysAhead).map { "\(idPrefix)\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        guard UserDefaults.standard.bool(forKey: AppSettings.reminderKey) else { return }

        let days = ((try? context.fetch(FetchDescriptor<StudyDay>())) ?? []).map(\.day)
        let streak = Streak.count(days)
        let doneToday = Streak.didStudyToday(days)
        let minutes = UserDefaults.standard.object(forKey: AppSettings.reminderMinutesKey) as? Int ?? AppSettings.defaultReminderMinutes
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        for offset in 0..<daysAhead {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let fireDate = calendar.date(byAdding: .minute, value: minutes, to: day),
                  fireDate > .now, !(offset == 0 && doneToday)
            else { continue }

            let content = UNMutableNotificationContent()
            content.title = "今日の文法"
            // Only tomorrow's reminder can know the streak is still alive.
            if offset <= 1, streak > 0 {
                content.body = "Keep your \(streak)-day streak going: a few minutes of grammar."
            } else {
                content.body = "Time for today's grammar lesson. A few minutes is enough."
            }
            content.sound = .default
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            center.add(UNNotificationRequest(identifier: ids[offset], content: content, trigger: trigger))
        }
    }
}
