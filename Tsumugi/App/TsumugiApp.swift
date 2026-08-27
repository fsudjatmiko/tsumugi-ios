import SwiftData
import SwiftUI

@main
struct TsumugiApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            CharacterCard.self,
            ReviewLog.self,
            ChatMessage.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Color.tsumugiDustyDenim)
                .task {
                    await SeedDataLoader.shared.preloadSeedDataIfNeeded(context: container.mainContext)
                }
        }
        .modelContainer(container)
    }
}
