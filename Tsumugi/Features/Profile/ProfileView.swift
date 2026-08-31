import PhotosUI
import SwiftData
import SwiftUI

/// User Profile & Settings Screen displaying learning progress, avatar selection, preferences, and data management.
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var allCards: [CharacterCard]
    @Query(sort: \ReviewLog.timestamp, order: .reverse) private var allLogs: [ReviewLog]

    // MARK: - User Preferences & Profile State (AppStorage / State)
    @AppStorage("profile_display_name") private var displayName: String = "Learner"
    @AppStorage("profile_jlpt_level") private var targetLevel: String = "JLPT N5"
    @AppStorage("profile_selected_emoji") private var selectedEmoji: String = "🦊"
    @AppStorage("profile_daily_goal") private var dailyGoal: Int = 20
    @AppStorage("profile_auto_audio") private var autoPlayAudio: Bool = true
    @AppStorage("profile_show_furigana") private var showFuriganaHint: Bool = true

    // PhotosPicker, Action Sheet & Preview States
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var customAvatarData: Data? = nil
    @State private var showActionSheet: Bool = false
    @State private var showPhotosPicker: Bool = false
    @State private var showEmojiInputSheet: Bool = false
    @State private var emojiInputText: String = ""
    @State private var isShowingPreview: Bool = false
    @State private var showResetConfirmation: Bool = false
    @State private var resetToastMessage: String?

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

                if customAvatarData != nil || !selectedEmoji.isEmpty {
                    Button("Remove Photo", role: .destructive) {
                        customAvatarData = nil
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
                        customAvatarData = data
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
                    avatarCircleView(size: 80, fontSize: 42)
                        .frame(width: 80, height: 80)
                        .background(Color.tsumugiFrozenWater.opacity(0.35))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.tsumugiDustyDenim.opacity(0.3), lineWidth: 2)
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

    @ViewBuilder
    private func avatarCircleView(size: CGFloat, fontSize: CGFloat) -> some View {
        if let data = customAvatarData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else if !selectedEmoji.isEmpty {
            Text(selectedEmoji)
                .font(.system(size: fontSize))
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.tsumugiDustyDenim.opacity(0.7))
                .padding(size * 0.1)
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
            } label: {
                Label("Unlocked Characters", systemImage: "character.book.closed.fill")
                    .foregroundStyle(Color.tsumugiTextPrimary)
            }

            LabeledContent {
                Text("\(masteredCardsCount)")
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.tsumugiDustyDenim)
            } label: {
                Label("Mastered Cards (≥ 21d)", systemImage: "sparkles")
                    .foregroundStyle(Color.tsumugiTextPrimary)
            }

            LabeledContent {
                Text("\(totalReviewsCount)")
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.medium)
            } label: {
                Label("Lifetime Reviews", systemImage: "clock.arrow.circlepath")
                    .foregroundStyle(Color.tsumugiTextPrimary)
            }

            LabeledContent {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(currentStreak) \(currentStreak == 1 ? "day" : "days")")
                        .font(.subheadline.monospacedDigit())
                        .fontWeight(.bold)
                }
            } label: {
                Label("Current Streak", systemImage: "flame")
                    .foregroundStyle(Color.tsumugiTextPrimary)
            }

            LabeledContent {
                Text("\(longestStreak) \(longestStreak == 1 ? "day" : "days")")
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.medium)
            } label: {
                Label("Longest Streak", systemImage: "trophy.fill")
                    .foregroundStyle(Color.tsumugiTextPrimary)
            }
        }
    }

    // MARK: - 4. Learning Preferences Section

    private var preferencesSection: some View {
        Section("Learning Preferences") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Daily Review Goal", systemImage: "target")
                        .foregroundStyle(Color.tsumugiTextPrimary)
                    Spacer()
                    Text("\(dailyGoal) cards")
                        .font(.subheadline.monospacedDigit())
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.tsumugiDustyDenim)
                }

                Slider(
                    value: Binding(
                        get: { Double(dailyGoal) },
                        set: { dailyGoal = Int($0) }
                    ),
                    in: 5...50,
                    step: 5
                )
                .tint(Color.tsumugiDustyDenim)
            }
            .padding(.vertical, 4)

            Toggle(isOn: $autoPlayAudio) {
                Label("Auto-Play Audio on Flip", systemImage: "speaker.wave.2.fill")
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
        Section {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                Label("Reset Learning Progress", systemImage: "arrow.counterclockwise.circle.fill")
            }
        } footer: {
            Text("Tsumugi (紡ぎ) runs 100% on-device. All learning data and review metrics remain strictly private on your device.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Native System Emoji Input Sheet

    private var emojiInputSheetView: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Type or select any emoji from the keyboard")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                EmojiInputField(text: $emojiInputText) { chosenEmoji in
                    customAvatarData = nil
                    selectedEmoji = chosenEmoji
                    showEmojiInputSheet = false
                }
                .frame(width: 80, height: 80)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.tsumugiDustyDenim, lineWidth: 2))

                Spacer()
            }
            .padding(.horizontal, 24)
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

                avatarCircleView(size: 200, fontSize: 108)
                    .frame(width: 200, height: 200)
                    .background(Color.tsumugiFrozenWater.opacity(0.35))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.tsumugiDustyDenim.opacity(0.3), lineWidth: 3))
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

    // MARK: - Streak Calculators

    private func calculateStreak(from logs: [ReviewLog]) -> Int {
        guard !logs.isEmpty else { return 0 }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)
        let reviewDays = Set(logs.map { calendar.startOfDay(for: $0.timestamp) })

        var checkDate: Date
        if reviewDays.contains(today) {
            checkDate = today
        } else {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  reviewDays.contains(yesterday) else {
                return 0
            }
            checkDate = yesterday
        }

        var streak = 0
        while reviewDays.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }
        return streak
    }

    private func calculateLongestStreak(from logs: [ReviewLog]) -> Int {
        guard !logs.isEmpty else { return 0 }
        let calendar = Calendar.current
        let reviewDays = Array(Set(logs.map { calendar.startOfDay(for: $0.timestamp) })).sorted()

        guard !reviewDays.isEmpty else { return 0 }

        var maxStreak = 1
        var currentRunningStreak = 1

        for i in 1..<reviewDays.count {
            let prev = reviewDays[i - 1]
            let curr = reviewDays[i]

            if let nextDay = calendar.date(byAdding: .day, value: 1, to: prev), nextDay == curr {
                currentRunningStreak += 1
                maxStreak = max(maxStreak, currentRunningStreak)
            } else {
                currentRunningStreak = 1
            }
        }

        return maxStreak
    }
}

// MARK: - Focused Emoji Input Field (Auto-focuses System Keyboard)

private struct EmojiInputField: UIViewRepresentable {
    @Binding var text: String
    var onEmojiSelected: (String) -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.textAlignment = .center
        textField.font = UIFont.systemFont(ofSize: 44)
        textField.tintColor = .clear
        textField.delegate = context.coordinator
        DispatchQueue.main.async {
            textField.becomeFirstResponder()
        }
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EmojiInputField

        init(_ parent: EmojiInputField) {
            self.parent = parent
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard !string.isEmpty else { return true }

            // Extract the last entered glyph / emoji
            let candidate = String(string.suffix(1))
            parent.text = candidate
            parent.onEmojiSelected(candidate)
            return false
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(PreviewContainer.shared)
}
