import SwiftData
import SwiftUI

@main
struct KotoApp: App {
    private let container: ModelContainer
    private let service: ChatService = ClaudeChatService()
    @State private var chat: ChatViewModel
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppSettings.themeKey) private var theme = Theme.classic

    init() {
        do {
            container = try ModelContainer(
                for: SavedWord.self, SavedGrammar.self, MistakeRecord.self, StoredMessage.self,
                LessonProgress.self, StudyDay.self
            )
        } catch {
            fatalError("Couldn't open the on-device database: \(error)")
        }
        _chat = State(initialValue: ChatViewModel(context: container.mainContext, service: service))
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Chat", systemImage: "bubble.left.and.bubble.right.fill") {
                    ChatView(model: chat)
                }
                Tab("Learn", systemImage: "graduationcap.fill") {
                    CourseView(service: service)
                }
            }
            .environment(\.theme, theme)
            .tint(theme.accent)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) {
            // Today's reminder is dropped once the lesson is done, and the streak in the text stays current.
            if scenePhase == .active { Reminders.reschedule(context: container.mainContext) }
        }
    }
}
