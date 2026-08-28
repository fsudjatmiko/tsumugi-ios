import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(
                onSelectStudyTab: {
                    selectedTab = 1
                },
                onSelectSpatialTab: {
                    selectedTab = 2
                }
            )
            .tabItem {
                Label("Learn", systemImage: "chart.bar.fill")
            }
            .tag(0)

            StudySessionView()
                .tabItem {
                    Label("Study", systemImage: "rectangle.portrait.on.rectangle.portrait.angled.fill")
                }
                .tag(1)

            SpatialLabView()
                .tabItem {
                    Label("Spatial", systemImage: "cube.transparent.fill")
                }
                .tag(2)

            ChatPracticeView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(3)
        }
        .tint(Color.tsumugiDustyDenim)
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewContainer.shared)
        .preferredColorScheme(.light)
}
