import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                Text("Learn Dashboard")
                    .navigationTitle("Learn")
            }
            .tabItem {
                Label("Learn", systemImage: "chart.bar.fill")
            }

            NavigationStack {
                Text("Study Session")
                    .navigationTitle("Study")
            }
            .tabItem {
                Label("Study", systemImage: "rectangle.portrait.on.rectangle.portrait.fill")
            }

            NavigationStack {
                Text("Spatial Lab")
                    .navigationTitle("Spatial")
            }
            .tabItem {
                Label("Spatial", systemImage: "arkit")
            }

            NavigationStack {
                Text("Chat Partner")
                    .navigationTitle("Chat")
            }
            .tabItem {
                Label("Chat", systemImage: "bubble.left.and.text.bubble.right.fill")
            }
        }
        .tint(.primary)
    }
}

#Preview {
    ContentView()
}
