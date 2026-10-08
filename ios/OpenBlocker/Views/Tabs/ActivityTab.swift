// Activity tab - simplified for new architecture

import SwiftUI
import Charts

struct ActivityTab: View {
    @ObservedObject var appState = AppState.shared
    
    var body: some View {
        ZStack {
            Color.brickCanvas
                .ignoresSafeArea()
            
            if isEmptyActivity {
                emptyState
            } else {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Weekly Activity")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.brickInk)
                        .padding(.top, 24)
                    
                    let weekStart = Self.mondayWeekStart()
                    let weekdayLabels = ["M", "T", "W", "T", "F", "S", "S"]
                    let weekDays: [Date] = (0..<7).compactMap { index in
                        Calendar.current.date(byAdding: .day, value: index, to: weekStart)
                    }
                    let weekDurations = weekDays.map { appState.focusStats(on: $0).duration }
                    let dailyHours = weekDurations.map { $0 / 3600.0 }
                    let avgSeconds = weekDurations.reduce(0, +) / 7
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Average per day")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color.brickMuted)
                        
                        let hours = Int(avgSeconds) / 3600
                        let minutes = (Int(avgSeconds) % 3600) / 60
                        
                        Text("\(hours)h \(minutes)m")
                            .font(.system(size: 50, weight: .light))
                            .foregroundColor(Color.brickInk)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    
                    let yMax = Self.chartYMax(for: dailyHours)
                    let yStep = yMax <= 2 ? 1.0 : (yMax <= 4 ? 1.0 : 2.0)
                    let yTicks = Array(stride(from: 0.0, through: yMax, by: yStep))
                    
                    Chart {
                        ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                            BarMark(
                                x: .value("Day", day, unit: .day),
                                y: .value("Hours", dailyHours[index]),
                                width: .ratio(0.7)
                            )
                            .foregroundStyle(Color.brickChart)
                            .cornerRadius(8)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: weekDays) { value in
                            AxisValueLabel {
                                if let date = value.as(Date.self),
                                   let index = weekDays.firstIndex(of: date) {
                                    Text(weekdayLabels[index])
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color.brickSecondaryLabel)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .trailing, values: yTicks) { value in
                            AxisGridLine()
                                .foregroundStyle(Color.brickSecondaryLabel.opacity(0.35))
                            AxisValueLabel {
                                if let hours = value.as(Double.self) {
                                    Text(hours.truncatingRemainder(dividingBy: 1) == 0
                                         ? "\(Int(hours))"
                                         : String(format: "%.1f", hours))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(Color.brickSecondaryLabel)
                                }
                            }
                        }
                    }
                    .chartYScale(domain: 0.0...yMax)
                    .frame(height: 128)
                    .padding(.horizontal, 24)
                    
                    ForEach(0..<7, id: \.self) { dayOffset in
                        let calendar = Calendar.current
                        let day = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
                        let stats = appState.focusStats(on: day)
                        
                        DayCard(date: day, duration: stats.duration, sessionCount: stats.sessions)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, BrickLayout.tabScrollInset)
            }
            .accessibilityIdentifier(AccessibilityID.activityScroll)
            }
        }
    }
    
    private var isEmptyActivity: Bool {
        !appState.isBlocking && appState.history.isEmpty
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("No sessions yet")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color.brickInk)
            Text("Block with a key and it will show up here.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color.brickMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier(AccessibilityID.activityScroll)
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

struct DayCard: View {
    let date: Date
    let duration: TimeInterval
    let sessionCount: Int
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.brickCard)
            
            VStack(alignment: .leading, spacing: 8) {
                let isToday = Calendar.current.isDateInToday(date)
                HStack(spacing: 6) {
                    if isToday {
                        Circle()
                            .fill(Color.brickAccent)
                            .frame(width: 6, height: 6)
                    }
                    
                    Text(isToday ? "TODAY" : date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)).uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.brickMuted)
                        .tracking(0.6)
                }
                
                let hours = Int(duration) / 3600
                let minutes = (Int(duration) % 3600) / 60
                Text("\(hours)h \(minutes)m")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(Color.brickInk)
                
                Text("\(sessionCount) session\(sessionCount == 1 ? "" : "s")")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color.brickMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
    }
}
