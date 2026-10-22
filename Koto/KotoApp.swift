import SwiftData
import SwiftUI

@main
struct KotoApp: App {
    var body: some Scene {
        WindowGroup {
            ChatView()
        }
        .modelContainer(for: SavedWord.self)
    }
}
