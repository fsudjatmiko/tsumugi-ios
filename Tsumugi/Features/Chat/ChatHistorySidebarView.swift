import SwiftData
import SwiftUI

/// Sidebar view listing all historical chat sessions grouped by date with a prominent "New Chat" button, swipe-to-delete, and context menu actions.
struct ChatHistorySidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedSession: ChatSession?
    var onSessionSelected: ((ChatSession) -> Void)?
    var onNewChatTapped: (() -> Void)?

    @Query(sort: \ChatSession.updatedAt, order: .reverse)
    private var allSessions: [ChatSession]

    // Rename Dialog State
    @State private var sessionToRename: ChatSession?
    @State private var renameText: String = ""
    @State private var showingRenameAlert: Bool = false

    // Date Categorization
    private var todaySessions: [ChatSession] {
        allSessions.filter { Calendar.current.isDateInToday($0.updatedAt) }
    }

    private var yesterdaySessions: [ChatSession] {
        allSessions.filter { Calendar.current.isDateInYesterday($0.updatedAt) }
    }

    private var previousSevenDaysSessions: [ChatSession] {
        let calendar = Calendar.current
        let now = Date()
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return [] }
        return allSessions.filter { session in
            !calendar.isDateInToday(session.updatedAt) &&
            !calendar.isDateInYesterday(session.updatedAt) &&
            session.updatedAt >= sevenDaysAgo
        }
    }

    private var olderSessions: [ChatSession] {
        let calendar = Calendar.current
        let now = Date()
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return [] }
        return allSessions.filter { session in
            session.updatedAt < sevenDaysAgo
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // New Chat Action Pill
            newChatButton
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Grouped Session List
            List {
                if !todaySessions.isEmpty {
                    Section("Today") {
                        sessionRows(for: todaySessions)
                    }
                }

                if !yesterdaySessions.isEmpty {
                    Section("Yesterday") {
                        sessionRows(for: yesterdaySessions)
                    }
                }

                if !previousSevenDaysSessions.isEmpty {
                    Section("Previous 7 Days") {
                        sessionRows(for: previousSevenDaysSessions)
                    }
                }

                if !olderSessions.isEmpty {
                    Section("Older") {
                        sessionRows(for: olderSessions)
                    }
                }
            }
            .listStyle(.sidebar)
        }
        .navigationTitle("Conversations")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Rename Chat", isPresented: $showingRenameAlert) {
            TextField("Chat Title", text: $renameText)
            Button("Cancel", role: .cancel) {
                sessionToRename = nil
                renameText = ""
            }
            Button("Save") {
                if let target = sessionToRename {
                    let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        target.title = trimmed
                        target.updatedAt = Date()
                        try? modelContext.save()
                    }
                }
                sessionToRename = nil
                renameText = ""
            }
        } message: {
            Text("Enter a new title for this conversation thread.")
        }
    }

    // MARK: - New Chat Button

    private var newChatButton: some View {
        Button {
            if let onNewChatTapped = onNewChatTapped {
                onNewChatTapped()
            } else {
                let newSession = MLXChatService.shared.startNewSession(modelContext: modelContext)
                selectedSession = newSession
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.pencil")
                    .font(.subheadline)
                    .fontWeight(.bold)

                Text("New Chat")
                    .font(.subheadline)
                    .fontWeight(.bold)

                Spacer()

                Image(systemName: "plus")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
            .foregroundStyle(Color.tsumugiSpaceIndigo)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.tsumugiChartreuse, in: Capsule())
            .shadow(color: Color.tsumugiChartreuse.opacity(0.35), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Session Rows

    @ViewBuilder
    private func sessionRows(for sessions: [ChatSession]) -> some View {
        ForEach(sessions) { session in
            let isSelected = selectedSession?.id == session.id

            Button {
                selectedSession = session
                onSessionSelected?(session)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(session.title)
                            .font(.subheadline)
                            .fontWeight(isSelected ? .bold : .medium)
                            .foregroundStyle(isSelected ? Color.tsumugiDustyDenim : Color.tsumugiTextPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text(formattedTime(session.updatedAt))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text(session.lastMessagePreview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .listRowBackground(
                isSelected
                    ? Color.tsumugiDustyDenim.opacity(0.12)
                    : Color.clear
            )
            // Trailing Swipe-to-Delete Action
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    deleteSession(session)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            // Context Menu Shortcut (Rename and Delete)
            .contextMenu {
                Button {
                    sessionToRename = session
                    renameText = session.title
                    showingRenameAlert = true
                } label: {
                    Label("Rename Chat", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    deleteSession(session)
                } label: {
                    Label("Delete Chat", systemImage: "trash")
                }
            }
        }
        .onDelete { indexSet in
            deleteSessions(at: indexSet, in: sessions)
        }
    }

    // MARK: - Deletion Handlers

    private func deleteSessions(at offsets: IndexSet, in subset: [ChatSession]) {
        for index in offsets {
            guard index < subset.count else { continue }
            deleteSession(subset[index])
        }
    }

    private func deleteSession(_ session: ChatSession) {
        withAnimation {
            // Emit medium haptic feedback on removal
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            let remaining = allSessions.filter { $0.id != session.id }

            // Active Selection Fallback
            if selectedSession?.id == session.id {
                if let nextSession = remaining.first {
                    selectedSession = nextSession
                } else {
                    // Automatically initialize new starter session if all sessions are deleted
                    let freshSession = MLXChatService.shared.startNewSession(modelContext: modelContext)
                    selectedSession = freshSession
                }
            }

            // Remove model and cascade delete messages
            MLXChatService.shared.deleteSession(session, modelContext: modelContext)
            try? modelContext.save()
        }
    }

    // MARK: - Date Formatting

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else {
            formatter.dateFormat = "M/d"
        }
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        ChatHistorySidebarView(selectedSession: .constant(nil))
    }
    .modelContainer(PreviewContainer.shared)
}
