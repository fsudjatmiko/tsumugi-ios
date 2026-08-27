import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(onSelectStudyTab: {
                selectedTab = 1
            })
            .tabItem {
                Label("Learn", systemImage: "chart.bar.fill")
            }
            .tag(0)

            StudySessionView()
                .tabItem {
                    Label("Study", systemImage: "rectangle.portrait.on.rectangle.portrait.fill")
                }
                .tag(1)

            SpatialLabView()
                .tabItem {
                    Label("Spatial", systemImage: "arkit")
                }
                .tag(2)

            NavigationStack {
                Text("Chat Partner")
                    .navigationTitle("Chat")
            }
            .tabItem {
                Label("Chat", systemImage: "bubble.left.and.text.bubble.right.fill")
            }
            .tag(3)
        }
        .tint(Color.tsumugiDustyDenim)
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewContainer.shared)
}
