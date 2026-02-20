import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    private let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        ZStack {
            TimeBasedGradientBackground()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Your Journey")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        Text("Keep showing up for yourself")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 70)

                    // Stats row
                    HStack(spacing: 16) {
                        StatCard(value: "\(viewModel.currentStreak)", label: "Current\nStreak", icon: "flame.fill", iconColor: HypeColors.streak)
                        StatCard(value: "\(viewModel.longestStreak)", label: "Longest\nStreak", icon: "trophy.fill", iconColor: Color.yellow)
                        StatCard(value: "\(viewModel.totalCompletions)", label: "Total\nCheck-ins", icon: "checkmark.seal.fill", iconColor: HypeColors.primary)
                    }
                    .padding(.horizontal, 24)

                    // Calendar
                    GlassCard(cornerRadius: 20, padding: 20) {
                        VStack(spacing: 16) {
                            // Month navigation
                            HStack {
                                Button(action: viewModel.previousMonth) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.white)
                                        .frame(width: 32, height: 32)
                                }

                                Spacer()

                                Text(viewModel.monthYearString)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)

                                Spacer()

                                Button(action: viewModel.nextMonth) {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white)
                                        .frame(width: 32, height: 32)
                                }
                            }

                            // Week day headers
                            HStack {
                                ForEach(weekDays, id: \.self) { day in
                                    Text(day)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.5))
                                        .frame(maxWidth: .infinity)
                                }
                            }

                            // Calendar grid
                            let columns = Array(repeating: GridItem(.flexible()), count: 7)
                            LazyVGrid(columns: columns, spacing: 8) {
                                // Offset empty cells
                                ForEach(0..<viewModel.firstWeekdayOffset, id: \.self) { _ in
                                    Color.clear.frame(height: 36)
                                }

                                ForEach(viewModel.daysInCurrentMonth, id: \.self) { date in
                                    CalendarDay(
                                        date: date,
                                        isCompleted: viewModel.isCompleted(date: date),
                                        isToday: Calendar.current.isDateInToday(date)
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 120)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.loadData()
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)

            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Calendar Day
struct CalendarDay: View {
    let date: Date
    let isCompleted: Bool
    let isToday: Bool

    var body: some View {
        ZStack {
            if isCompleted {
                Circle()
                    .fill(HypeColors.primary)
                    .frame(width: 34, height: 34)
            } else if isToday {
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 34, height: 34)
            }

            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 14, weight: isToday || isCompleted ? .semibold : .regular))
                .foregroundColor(
                    isCompleted ? .white :
                    isToday ? .white :
                    .white.opacity(0.55)
                )

            if isCompleted {
                // Small checkmark
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .offset(x: 8, y: -8)
            }
        }
        .frame(height: 36)
    }
}
