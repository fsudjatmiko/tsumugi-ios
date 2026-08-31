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
                Label("Learn", systemImage: "book.fill")
            }
            .tag(0)

            StudySessionView()
                .tabItem {
                    Label("Review", systemImage: "rectangle.stack.fill")
                }
                .tag(1)

            SpatialLabView()
                .tabItem {
                    Label("Spatial Lab", systemImage: "cube.transparent")
                }
                .tag(2)

            ChatPracticeView()
                .tabItem {
                    Label("Practice", systemImage: "bubble.left.and.bubble.right.fill")
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
