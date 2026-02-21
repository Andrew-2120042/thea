import SwiftUI

struct TodaysIntentionsView: View {
    @ObservedObject var viewModel: IntentionsViewModel
    let todaysAffirmation: String?
    let onDone: () -> Void

    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var newIntentionText = ""
    @State private var showAddIntention = false

    private var darkText: Color { Color(red: 0.08, green: 0.08, blue: 0.14) }
    private var mutedText: Color { Color(red: 0.42, green: 0.42, blue: 0.48) }

    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.96, blue: 0.94)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with title
                HStack {
                    Text("Your Focus Today")
                        .font(.system(size: 26, weight: .regular, design: .serif))
                        .foregroundColor(darkText)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)

                // Calendar header - day and month selector
                VStack(spacing: 16) {
                    HStack {
                        Text(dayOfWeek(selectedDate))
                            .font(.system(size: 40, weight: .regular, design: .serif))
                            .foregroundColor(darkText)

                        Spacer()

                        Button(action: { showDatePicker = true }) {
                            HStack(spacing: 8) {
                                Text(monthYear(selectedDate))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(mutedText)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(mutedText)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Week view
                    weekView
                        .padding(.top, 8)
                }
                .padding(.bottom, 20)

                Divider().padding(.horizontal, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Intentions
                        VStack(alignment: .leading, spacing: 16) {
                            if viewModel.intentions.isEmpty {
                                Text("No intentions set for today.")
                                    .font(.system(size: 16))
                                    .foregroundColor(mutedText)
                            } else {
                                ForEach(viewModel.intentions) { intention in
                                    IntentionRow(intention: intention) {
                                        Task { await viewModel.toggleCompletion(id: intention.id) }
                                    }
                                }

                                let done = viewModel.intentions.filter { $0.completed }.count
                                let total = viewModel.intentions.count
                                Text("\(done) of \(total) complete")
                                    .font(.system(size: 13))
                                    .foregroundColor(mutedText)
                                    .padding(.top, 4)
                            }

                            // Add intention button
                            Button(action: { showAddIntention = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(red: 0.55, green: 0.36, blue: 0.96))

                                    Text("Add Intention")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(darkText)

                                    Spacer()
                                }
                                .padding(16)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 12)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 28)

                        Divider().padding(.horizontal, 24)

                        // Affirmation reminder
                        if let affirmation = todaysAffirmation {
                            VStack(spacing: 12) {
                                Text("You said:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(mutedText)

                                Text("\"\(affirmation)\"")
                                    .font(.system(size: 20, weight: .regular, design: .serif))
                                    .foregroundColor(darkText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)

                                Text("Now go prove it. 🔥")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(red: 0.55, green: 0.36, blue: 0.96))
                            }
                            .padding(.vertical, 8)
                        }

                        // Bottom padding
                        Color.clear.frame(height: 100)
                    }
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert("Add Intention", isPresented: $showAddIntention) {
            TextField("What do you want to accomplish?", text: $newIntentionText)
            Button("Cancel", role: .cancel) {
                newIntentionText = ""
            }
            Button("Add") {
                if !newIntentionText.isEmpty {
                    viewModel.addIntention(text: newIntentionText)
                    Task {
                        await viewModel.save(feeling: nil)
                    }
                    newIntentionText = ""
                }
            }
        }
    }

    // MARK: - Week View
    private var weekView: some View {
        HStack(spacing: 0) {
            ForEach(weekDays(for: selectedDate), id: \.self) { date in
                let isFuture = isFutureDate(date)

                Button(action: {
                    if !isFuture {
                        selectedDate = date
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(dayLetter(date))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isFuture ? mutedText.opacity(0.3) : mutedText)

                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.system(size: 24, weight: isToday(date) ? .bold : .regular))
                            .foregroundColor(isFuture ? mutedText.opacity(0.2) : (isToday(date) ? darkText : mutedText.opacity(0.6)))
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isFuture)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Helper Functions
    private func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private func monthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date).uppercased()
    }

    private func dayLetter(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date).uppercased()
    }

    private func weekDays(for date: Date) -> [Date] {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return []
        }

        var dates: [Date] = []
        var currentDate = weekInterval.start

        while currentDate < weekInterval.end {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return dates
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }

    private func isFutureDate(_ date: Date) -> Bool {
        Calendar.current.compare(date, to: Date(), toGranularity: .day) == .orderedDescending
    }
}

// MARK: - Intention row with checkbox
private struct IntentionRow: View {
    let intention: Intention
    let onToggle: () -> Void

    private var darkText: Color { Color(red: 0.08, green: 0.08, blue: 0.14) }
    private var green: Color { Color(red: 0.07, green: 0.72, blue: 0.51) }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(intention.completed ? green : Color(red: 0.82, green: 0.82, blue: 0.84), lineWidth: 2)
                        .frame(width: 26, height: 26)
                    if intention.completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(green)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(intention.text)
                        .font(.system(size: 16))
                        .foregroundColor(darkText)
                        .strikethrough(intention.completed, color: darkText.opacity(0.5))

                    if let completedAt = intention.completedAt {
                        Text("Done at \(completedAt, style: .time)")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: intention.completed)
    }
}
