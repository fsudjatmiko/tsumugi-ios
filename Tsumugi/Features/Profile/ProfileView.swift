import PhotosUI
import SwiftData
import SwiftUI

/// User Profile & Settings Screen displaying learning progress, avatar selection, preferences, and data management.
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var allCards: [CharacterCard]
    @Query(sort: \ReviewLog.timestamp, order: .reverse) private var allLogs: [ReviewLog]

    // MARK: - User Preferences & Profile State (AppStorage / Persistence)
    @AppStorage("profile_display_name") private var displayName: String = "Learner"
    @AppStorage("profile_jlpt_level") private var targetLevel: String = "JLPT N5"
    @AppStorage("profile_selected_emoji") private var selectedEmoji: String = "🦊"
    @AppStorage("profile_avatar_data") private var storedAvatarData: Data = Data()
    @AppStorage("profile_daily_goal") private var dailyGoal: Int = 20
    @AppStorage("profile_auto_audio") private var autoPlayAudio: Bool = true
    @AppStorage("profile_show_furigana") private var showFuriganaHint: Bool = true

    // PhotosPicker, Action Sheet & Preview States
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showActionSheet: Bool = false
    @State private var showPhotosPicker: Bool = false
    @State private var showEmojiInputSheet: Bool = false
    @State private var emojiInputText: String = ""
    @State private var isShowingPreview: Bool = false
    @State private var showResetConfirmation: Bool = false
    @State private var resetToastMessage: String?

    private var activeAvatarData: Data? {
        storedAvatarData.isEmpty ? nil : storedAvatarData
    }

    private let targetLevels = ["JLPT N5", "JLPT N4", "JLPT N3", "JLPT N2", "JLPT N1", "Beginner Kana"]

    // MARK: - Computed Mastery Stats

    private var unlockedCount: Int {
        allCards.filter { $0.isUnlocked }.count
    }

    private var totalCardsCount: Int {
        allCards.count
    }

    private var totalReviewsCount: Int {
        allLogs.count
    }

    private var masteredCardsCount: Int {
        allCards.filter { $0.interval >= 21 }.count
    }

    private var currentStreak: Int {
        calculateStreak(from: allLogs)
    }

    private var longestStreak: Int {
        calculateLongestStreak(from: allLogs)
    }

    var body: some View {
        NavigationStack {
            List {
                // 1. Clean Apple ID / Contacts Header (Avatar + Change Photo Button)
                avatarHeaderSection

                // 2. User Details Section
                userDetailsSection

                // 3. Overall Mastery & Stats Section
                masteryStatsSection

                // 4. Learning Preferences Section
                preferencesSection

                // 5. Data Management Section
                dataManagementSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.tsumugiDustyDenim)
                }
            }
            .confirmationDialog(
                "Profile Photo",
                isPresented: $showActionSheet,
                titleVisibility: .visible
            ) {
                Button("Choose from Photos") {
                    showPhotosPicker = true
                }

                Button("Choose Emoji") {
                    emojiInputText = ""
                    showEmojiInputSheet = true
                }

                if activeAvatarData != nil || !selectedEmoji.isEmpty {
                    Button("Remove Photo", role: .destructive) {
                        storedAvatarData = Data()
                        selectedEmoji = ""
                    }
                }

                Button("Cancel", role: .cancel) {}
            }
            .photosPicker(
                isPresented: $showPhotosPicker,
                selection: $selectedPhotoItem,
                matching: .images
            )
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        storedAvatarData = data
                        selectedEmoji = ""
                    }
                }
            }
            .sheet(isPresented: $showEmojiInputSheet) {
                emojiInputSheetView
                    .presentationDetents([.height(240)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingPreview) {
                enlargedAvatarPreviewSheet
                    .presentationDetents([.height(340)])
                    .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                "Reset Learning Progress?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset All Progress", role: .destructive) {
                    resetLearningProgress()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset all SRS card intervals, repetition history, and review logs back to their initial state. This action cannot be undone.")
            }
            .alert(
                resetToastMessage ?? "Notice",
                isPresented: Binding(
                    get: { resetToastMessage != nil },
                    set: { if !$0 { resetToastMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    resetToastMessage = nil
                }
            }
        }
    }

    // MARK: - 1. Avatar Header Section

    private var avatarHeaderSection: some View {
        Section {
            VStack(spacing: 10) {
                // Circular Avatar (80x80) with Tap to Preview
                Button {
                    isShowingPreview = true
                } label: {
                    UserAvatarView(
                        imageData: activeAvatarData,
                        emoji: selectedEmoji,
                        size: 80,
                        strokeWidth: 2
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View profile avatar preview")

                // "Change Photo" Action Button
                Button {
                    showActionSheet = true
                } label: {
                    Text("Change Photo")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.tsumugiDustyDenim)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Change profile photo")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
    }

    // MARK: - 2. User Details Section

    private var userDetailsSection: some View {
        Section {
            HStack {
                Text("Learner Name")
                    .foregroundStyle(Color.tsumugiTextPrimary)
                Spacer()
                TextField("Learner Name", text: $displayName)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }

            Picker("Target Level", selection: $targetLevel) {
                ForEach(targetLevels, id: \.self) { level in
                    Text(level).tag(level)
                }
            }
            .tint(Color.tsumugiDustyDenim)
        }
    }

    // MARK: - 3. Overall Mastery & Stats Section

    private var masteryStatsSection: some View {
        Section("Mastery & Progress") {
            LabeledContent {
                Text("\(unlockedCount) / \(max(1, totalCardsCount))")
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.medium)
                    .foregroundStyle(Color.tsumugiTextPrimary)
            } label: {
                Label("Unlocked Characters", systemImage: "character.book.closed.fill")
                    .foregroundStyle(Color.tsumugiTextPrimary)
            }

            LabeledContent {
                Text("\(masteredCardsCount)")
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.medium)
                    .foregroundStyle(Color.tsumugiDustyDenim)
            } label: {
                Label("Mastered (21d+ Interval)", systemImage: "sparkles")
                    .foregroundStyle(Color.tsumugiTextPrimary)
            }

            LabeledContent {
                Text("\(totalReviewsCount)")
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.medium)
                    .foregroundStyle(Color.tsumugiTextPrimary)
            } label: {
                Label("Total Reviews Logged", systemImage: "arrow.counterclockwise.circle.fill")
                    .foregroundStyle(Color.tsumugiTextPrimary)
            }

            LabeledContent {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color.orange)
                    Text("\(currentStreak) \(currentStreak == 1 ? "day" : "days")")
                        .font(.subheadline.monospacedDigit())
                        .fontWeight(.bold)
                        .foregroundStyle(Color.orange)
                }
            } label: {
                Label("Current Streak", systemImage: "flame.fill")
                    .foregroundStyle(Color.tsumugiTextPrimary)
            }

            LabeledContent {
                Text("\(longestStreak) \(longestStreak == 1 ? "day" : "days")")
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.medium)
                    .foregroundStyle(Color.tsumugiTextPrimary)
            } label: {
                Label("Longest Streak", systemImage: "trophy.fill")
                    .foregroundStyle(Color.tsumugiTextPrimary)
            }
        }
    }

    // MARK: - 4. Learning Preferences Section

    private var preferencesSection: some View {
        Section("Study Preferences") {
            Stepper(value: $dailyGoal, in: 5...100, step: 5) {
                HStack {
                    Label("Daily Review Goal", systemImage: "target")
                        .foregroundStyle(Color.tsumugiTextPrimary)
                    Spacer()
                    Text("\(dailyGoal) cards")
                        .font(.subheadline.monospacedDigit())
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }

            Toggle(isOn: $autoPlayAudio) {
                Label("Auto-play Pronunciation", systemImage: "speaker.wave.2.fill")
                    .foregroundStyle(Color.tsumugiTextPrimary)
            }
            .tint(Color.tsumugiDustyDenim)

            Toggle(isOn: $showFuriganaHint) {
                Label("Show Furigana Hints", systemImage: "character.textbox")
                    .foregroundStyle(Color.tsumugiTextPrimary)
            }
            .tint(Color.tsumugiDustyDenim)
        }
    }

    // MARK: - 5. Data Management Section

    private var dataManagementSection: some View {
        Section("Data & Maintenance") {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Label("Reset Study Progress", systemImage: "arrow.counterclockwise")
                    Spacer()
                }
            }
        }
    }

    // MARK: - System Emoji Picker Sheet

    private var emojiInputSheetView: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Enter any emoji to set as your profile avatar.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                TextField("Type Emoji (e.g. 🦊, 🌸, ⛩️)", text: $emojiInputText)
                    .font(.system(size: 36))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 32)
                    .onChange(of: emojiInputText) { _, newValue in
                        let lastGrapheme = String(newValue.suffix(1))
                        if !lastGrapheme.isEmpty {
                            selectedEmoji = lastGrapheme
                            storedAvatarData = Data()
                            showEmojiInputSheet = false
                        }
                    }

                Spacer()
            }
            .padding(.top, 16)
            .navigationTitle("Choose Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showEmojiInputSheet = false
                    }
                }
            }
        }
    }

    // MARK: - Lightweight Enlarged Avatar Preview Modal Sheet

    private var enlargedAvatarPreviewSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                UserAvatarView(
                    imageData: activeAvatarData,
                    emoji: selectedEmoji,
                    size: 180,
                    strokeWidth: 3
                )
                .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)

                VStack(spacing: 4) {
                    Text(displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.tsumugiTextPrimary)

                    Text(targetLevel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .navigationTitle("Avatar Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") {
                        isShowingPreview = false
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.tsumugiDustyDenim)
                }
            }
        }
    }

    // MARK: - Reset Operation

    private func resetLearningProgress() {
        for log in allLogs {
            modelContext.delete(log)
        }

        for card in allCards {
            card.interval = 0
            card.repetitions = 0
            card.easeFactor = 2.5
            card.nextReviewDate = Date.now
        }

        try? modelContext.save()
        resetToastMessage = "Learning progress has been successfully reset."
    }

    // MARK: - Streak Helpers

    private func calculateStreak(from logs: [ReviewLog]) -> Int {
        guard !logs.isEmpty else { return 0 }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var uniqueDays = Set<Date>()
        for log in logs {
            let day = calendar.startOfDay(for: log.timestamp)
            uniqueDays.insert(day)
        }

        var streak = 0
        var checkDay = today

        if !uniqueDays.contains(checkDay) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
            if uniqueDays.contains(yesterday) {
                checkDay = yesterday
            } else {
                return 0
            }
        }

        while uniqueDays.contains(checkDay) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDay) else { break }
            checkDay = prev
        }

        return streak
    }

    private func calculateLongestStreak(from logs: [ReviewLog]) -> Int {
        guard !logs.isEmpty else { return 0 }
        let calendar = Calendar.current

        var uniqueDays = Set<Date>()
        for log in logs {
            let day = calendar.startOfDay(for: log.timestamp)
            uniqueDays.insert(day)
        }

        let sortedDays = uniqueDays.sorted(by: <)
        var maxStreak = 0
        var currentStreak = 0
        var previousDay: Date?

        for day in sortedDays {
            if let prev = previousDay {
                if let nextExpected = calendar.date(byAdding: .day, value: 1, to: prev),
                   calendar.isDate(day, inSameDayAs: nextExpected) {
                    currentStreak += 1
                } else {
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            previousDay = day
            maxStreak = max(maxStreak, currentStreak)
        }

        return maxStreak
    }
}

#Preview {
    ProfileView()
        .modelContainer(PreviewContainer.shared)
}
