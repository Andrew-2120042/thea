import SwiftUI

struct StatsTabView: View {
    @ObservedObject var viewModel: StatsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Insights")
                        .font(.system(size: 26, weight: .regular, design: .serif))
                        .foregroundColor(Color(hex: "#1F2937"))

                    Spacer()

                    // Time period picker
                    Menu {
                        ForEach(StatsViewModel.TimePeriod.allCases, id: \.self) { period in
                            Button(period.rawValue) {
                                viewModel.selectedTimePeriod = period
                                Task {
                                    await viewModel.loadStats()
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedTimePeriod.rawValue)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "#6B7280"))

                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#6B7280"))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Divider()
                    .padding(.horizontal, 20)

                // Current Streak
                streakSection

                Divider()
                    .padding(.horizontal, 20)

                // Weekly Stats
                weeklyStatsSection

                Divider()
                    .padding(.horizontal, 20)

                // Calendar Heatmap
                calendarHeatmapSection

                Divider()
                    .padding(.horizontal, 20)

                // Mood Tracker
                moodTrackerSection

                Divider()
                    .padding(.horizontal, 20)

                // Top Intentions
                topIntentionsSection

                // Bottom padding
                Color.clear.frame(height: 100)
            }
        }
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        VStack(spacing: 12) {
            Text("🔥 Current Streak")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#1F2937"))

            Text("\(viewModel.currentStreak)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(Color(hex: "#F97316"))

            Text("days")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#6B7280"))

            if viewModel.currentStreak > 0 {
                Text("Keep it going!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#10B981"))
            }

            if viewModel.longestStreak > viewModel.currentStreak {
                Text("Longest: \(viewModel.longestStreak) days")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#9CA3AF"))
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Weekly Stats Section

    private var weeklyStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📊 This Week")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#1F2937"))
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                statRow(
                    label: "Affirmations",
                    value: "\(viewModel.thisWeekAffirmations)/7",
                    isComplete: viewModel.thisWeekAffirmations >= 7
                )

                statRow(
                    label: "Intentions set",
                    value: "\(viewModel.thisWeekIntentions)/7",
                    isComplete: viewModel.thisWeekIntentions >= 7
                )

                if viewModel.thisWeekIntentions > 0 {
                    let totalIntentions = viewModel.thisWeekIntentions * 3 // Assume avg 3 per day
                    let percentage = Int((Double(viewModel.thisWeekIntentionsCompleted) / Double(totalIntentions)) * 100)

                    statRow(
                        label: "Tasks completed",
                        value: "\(viewModel.thisWeekIntentionsCompleted)/\(totalIntentions) (\(percentage)%)",
                        isComplete: false
                    )
                }

                statRow(
                    label: "Journals written",
                    value: "\(viewModel.thisWeekJournals)/7",
                    isComplete: viewModel.thisWeekJournals >= 7
                )
            }
            .padding(.horizontal, 20)
        }
    }

    private func statRow(label: String, value: String, isComplete: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#1F2937"))

            Spacer()

            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#1F2937"))

                if isComplete {
                    Text("✅")
                }
            }
        }
    }

    // MARK: - Calendar Heatmap

    private var calendarHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📅 Calendar")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#1F2937"))
                .padding(.horizontal, 20)

            // Calendar grid (simplified - last 35 days, 5 weeks)
            VStack(spacing: 4) {
                // Day labels
                HStack(spacing: 4) {
                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                        Text(day)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)

                // Calendar cells
                let calendar = Calendar.current
                let today = Date()

                ForEach(0..<5, id: \.self) { week in
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { day in
                            let daysAgo = (4 - week) * 7 + (6 - day)
                            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!

                            calendarCell(for: date)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }

            // Legend
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: "#10B981"))
                        .frame(width: 12, height: 12)
                    Text("Completed")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#6B7280"))
                }

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: "#E5E7EB"))
                        .frame(width: 12, height: 12)
                    Text("Missed")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#6B7280"))
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func calendarCell(for date: Date) -> some View {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        let completed = viewModel.calendarData[dateString] ?? false

        return Circle()
            .fill(completed ? Color(hex: "#10B981") : Color(hex: "#E5E7EB"))
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Mood Tracker

    private var moodTrackerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("😊 Mood Over Time")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#1F2937"))
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                ForEach(Array(viewModel.moodData.sorted(by: { $0.value > $1.value })), id: \.key) { mood, count in
                    moodBar(label: mood, count: count, maxCount: viewModel.moodData.values.max() ?? 1)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func moodBar(label: String, count: Int, maxCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#1F2937"))

                Spacer()

                Text("\(count)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#9CA3AF"))
            }

            GeometryReader { geometry in
                HStack(spacing: 4) {
                    ForEach(0..<count, id: \.self) { _ in
                        Circle()
                            .fill(Color(hex: "#8B5CF6"))
                            .frame(width: 8, height: 8)
                    }

                    Spacer()
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Top Intentions

    private var topIntentionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎯 Most Common Intentions")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#1F2937"))
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                ForEach(Array(viewModel.topIntentions.enumerated()), id: \.offset) { index, intention in
                    HStack {
                        Text("\(index + 1).")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .frame(width: 24)

                        Text(intention.text)
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#1F2937"))

                        Spacer()

                        Text("(\(intention.count) times)")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}
