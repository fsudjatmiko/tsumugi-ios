import SwiftData
import SwiftUI

/// Top-level container hosting the responsive navigation layout with sidebar drawer and active dialogue session.
struct ChatPracticeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatSession.updatedAt, order: .reverse)
    private var allSessions: [ChatSession]

    @State private var selectedSession: ChatSession?
    @State private var showingSidebarSheet: Bool = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad / Mac Split View
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    ChatHistorySidebarView(
                        selectedSession: $selectedSession,
                        onSessionSelected: { _ in },
                        onNewChatTapped: {
                            createNewSession()
                        }
                    )
                } detail: {
                    if let active = currentOrFallbackSession {
                        NavigationStack {
                            ChatDetailView(
                                session: active,
                                onToggleSidebar: {
                                    withAnimation {
                                        columnVisibility = columnVisibility == .all ? .detailOnly : .all
                                    }
                                },
                                onNewChat: {
                                    createNewSession()
                                }
                            )
                        }
                    } else {
                        emptyStateView
                    }
                }
            } else {
                // iPhone Stack + Slide-Over Sheet Drawer
                NavigationStack {
                    if let active = currentOrFallbackSession {
                        ChatDetailView(
                            session: active,
                            onToggleSidebar: {
                                showingSidebarSheet = true
                            },
                            onNewChat: {
                                createNewSession()
                            }
                        )
                    } else {
                        emptyStateView
                    }
                }
                .sheet(isPresented: $showingSidebarSheet) {
                    NavigationStack {
                        ChatHistorySidebarView(
                            selectedSession: $selectedSession,
                            onSessionSelected: { _ in
                                showingSidebarSheet = false
                            },
                            onNewChatTapped: {
                                createNewSession()
                                showingSidebarSheet = false
                            }
                        )
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showingSidebarSheet = false
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                            }
                        }
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
        }
        .task {
            ensureStarterSession()
        }
    }

    // MARK: - Session Resolution

    private var currentOrFallbackSession: ChatSession? {
        if let selected = selectedSession, allSessions.contains(where: { $0.id == selected.id }) {
            return selected
        }
        return allSessions.first
    }

    private func ensureStarterSession() {
        if allSessions.isEmpty {
            let session = MLXChatService.shared.startNewSession(modelContext: modelContext)
            selectedSession = session
        } else if selectedSession == nil {
            selectedSession = allSessions.first
        }
    }

    private func createNewSession() {
        withAnimation {
            let session = MLXChatService.shared.startNewSession(modelContext: modelContext)
            selectedSession = session
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.tsumugiDustyDenim)

            Text("No Active Chat")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.tsumugiTextPrimary)

            Text("Start a new dialogue session with Tsumugi to practice spoken Japanese.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                createNewSession()
            } label: {
                Label("Start New Conversation", systemImage: "plus")
                    .fontWeight(.bold)
                    .foregroundStyle(Color.tsumugiSpaceIndigo)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.tsumugiChartreuse, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

#Preview {
    ChatPracticeView()
        .modelContainer(PreviewContainer.shared)
}
