import SwiftData
import SwiftUI

@main
struct KotoApp: App {
    private let container: ModelContainer
    @State private var chat: ChatViewModel

    init() {
        do {
            container = try ModelContainer(for: SavedWord.self, StoredMessage.self)
        } catch {
            fatalError("Couldn't open the on-device database: \(error)")
        }
        _chat = State(initialValue: ChatViewModel(context: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            ChatView(model: chat)
        }
        .modelContainer(container)
    }
}
