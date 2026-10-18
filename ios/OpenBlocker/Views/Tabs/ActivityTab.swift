import SwiftUI
import Charts

struct ActivityTab: View {
    @ObservedObject var appState = AppState.shared
    
    var body: some View {
        Group {
            if isEmpty {
                ZStack {
                    ScreenCanvas()
                    EmptyStateView(
                        systemImage: "chart.bar.fill",
                        title: "No sessions yet",
                        message: "Hold the key to block, and your time will show up here."
                    )
                }
            } else {
                TabScreen(title: "Weekly activity", subtitle: "Time blocked this week") {
                    content
                }
            }
        }
        .accessibilityIdentifier(AccessibilityID.activityScroll)
    }
    
    private var isEmpty: Bool {
        !appState.isBlocking && appState.history.isEmpty
    }
    
    private var content: some View {
        let weekStart = Self.mondayWeekStart()
        let days = Self.days(from: weekStart)
        let lastWeek = Self.days(from: Calendar.current.date(byAdding: .day, value: -7, to: weekStart) ?? weekStart)
        let durations = days.map { appState.focusStats(on: $0).duration }
        let hours = durations.map { $0 / 3600 }
        let average = durations.reduce(0, +) / 7
        let lastAverage = lastWeek.map { appState.focusStats(on: $0).duration }.reduce(0, +) / 7
        let yMax = Self.chartYMax(for: hours)
        let recent: [DayStat] = (0..<7).compactMap { offset in
            guard let day = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let stats = appState.focusStats(on: day)
            return DayStat(date: day, duration: stats.duration, sessions: stats.sessions)
        }
        let longestDay = max(recent.map(\.duration).max() ?? 0, 1)
        
        return VStack(alignment: .leading, spacing: Space.xl) {
            VStack(alignment: .leading, spacing: Space.xxs) {
                Text("Avg blocked time")
                    .textStyle(.subhead)
                    .foregroundColor(Color.inkSecondary)
                Text(DurationText.hoursMinutes(average))
                    .textStyle(.largeTitle)
                    .foregroundColor(Color.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .numericTransition()
                if let change = WeekChange(current: average, previous: lastAverage) {
                    Label(change.text, systemImage: change.symbol)
                        .textStyle(.footnote)
                        .foregroundColor(Color.inkSecondary)
                }
            }
            
            Chart {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    BarMark(
                        x: .value("Day", day, unit: .day),
                        y: .value("Hours", hours[index]),
                        width: .ratio(0.42)
                    )
                    .foregroundStyle(Color.ink.opacity(Calendar.current.isDateInToday(day) ? 0.9 : 0.55))
                    .cornerRadius(4)
                }
                if average > 0 {
                    RuleMark(y: .value("Average", average / 3600))
                        .foregroundStyle(Color.inkTertiary)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .annotation(position: .trailing, alignment: .center, spacing: 4) {
                            Text("AVG")
                                .textStyle(.caption)
                                .foregroundColor(Color.inkInverse)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.inkSecondary))
                        }
                }
            }
            .chartXAxis {
                AxisMarks(values: days) { value in
                    AxisValueLabel(centered: true) {
                        if let date = value.as(Date.self) {
                            VStack(spacing: 1) {
                                Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                                    .textStyle(.caption, weight: .medium)
                                Text(date.formatted(.dateTime.day()))
                                    .textStyle(.caption, weight: .regular)
                            }
                            .foregroundColor(Calendar.current.isDateInToday(date) ? Color.ink : Color.inkTertiary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: [0, yMax / 2, yMax]) { value in
                    AxisGridLine().foregroundStyle(Color.hairline)
                    AxisValueLabel {
                        if let hours = value.as(Double.self), hours > 0 {
                            Text(hours == floor(hours) ? "\(Int(hours))h" : "\(Int(hours * 60))m")
                                .textStyle(.caption, weight: .regular)
                                .foregroundColor(Color.inkTertiary)
                        }
                    }
                }
            }
            .chartYScale(domain: 0...yMax)
            .frame(height: 170)
            
            VStack(spacing: Space.s) {
                ForEach(recent) { day in
                    DayCard(
                        date: day.date,
                        duration: day.duration,
                        sessionCount: day.sessions,
                        share: day.duration / longestDay
                    )
                }
            }
        }
    }
    
    private static func days(from start: Date) -> [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) }
    }
    
    private static func mondayWeekStart() -> Date {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = Calendar.current.timeZone
        return calendar.dateInterval(of: .weekOfYear, for: Date())?.start
            ?? WeeklySessionAggregator.startOfWeek(for: Date(), calendar: calendar)
    }
    
    private static func chartYMax(for hours: [Double]) -> Double {
        let peak = hours.max() ?? 0
        if peak <= 2 { return 2 }
        if peak <= 4 { return 4 }
        if peak <= 6 { return 6 }
        return ceil(peak)
    }
}

private struct DayStat: Identifiable {
    let date: Date
    let duration: TimeInterval
    let sessions: Int
    var id: Date { date }
}

/// "80% from last week" with an arrow. Nil when there is nothing to compare.
struct WeekChange: Equatable {
    let percent: Int
    let isUp: Bool
    
    init?(current: TimeInterval, previous: TimeInterval) {
        guard previous > 0 else { return nil }
        let change = (current - previous) / previous
        percent = Int((abs(change) * 100).rounded())
        isUp = change >= 0
    }
    
    var text: String { "\(percent)% from last week" }
    var symbol: String { isUp ? "arrow.up.right" : "arrow.down.right" }
}

struct DayCard: View {
    let date: Date
    let duration: TimeInterval
    let sessionCount: Int
    /// This day's time as a share of the longest day shown (0...1).
    let share: Double
    
    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            HStack(spacing: 5) {
                if isToday {
                    Circle().fill(Color.ink).frame(width: 5, height: 5)
                }
                Text(isToday ? "Today" : date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .textStyle(.caption)
                    .foregroundColor(Color.inkSecondary)
            }
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(DurationText.hoursMinutes(duration))
                        .textStyle(.title)
                        .foregroundColor(Color.ink)
                    Text("\(sessionCount) session\(sessionCount == 1 ? "" : "s")")
                        .textStyle(.subhead)
                        .foregroundColor(Color.inkSecondary)
                }
                Spacer(minLength: Space.l)
                ShareBar(share: share)
                    .frame(width: 96)
                    .padding(.bottom, 6)
            }
        }
        .padding(Space.m)
        .background(CardBackground(raised: isToday))
        .accessibilityElement(children: .combine)
    }
}

private struct ShareBar: View {
    let share: Double
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.fillQuiet)
                Capsule()
                    .fill(Color.ink)
                    .frame(width: max(share > 0 ? 3 : 0, geo.size.width * min(max(share, 0), 1)))
            }
        }
        .frame(height: 3)
    }
}
