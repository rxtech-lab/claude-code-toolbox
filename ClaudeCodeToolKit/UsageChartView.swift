import Charts
import SwiftUI

enum TimePeriod: String, CaseIterable {
    case today = "Today (hourly)"
    case week = "7 days"
    case twoWeeks = "14 days"
    case month = "30 days"
    
    var days: Int {
        switch self {
        case .today: return 0
        case .week: return 7
        case .twoWeeks: return 14
        case .month: return 30
        }
    }
}

// MARK: - Time Period Selector

struct TimePeriodSelector: View {
    @Binding var selectedPeriod: TimePeriod
    
    var body: some View {
        HStack {
            Spacer()
            Picker("", selection: $selectedPeriod) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Interactive Chart

struct InteractiveChart: View {
    let filteredDailyUsage: [DailyUsage]
    let filteredHourlyUsage: [HourlyUsage]
    let selectedPeriod: TimePeriod
    @State private var selectedDate: String?
    
    private var selectedDailyUsage: DailyUsage? {
        guard let selectedDate = selectedDate else { return nil }
        let selected = filteredDailyUsage.first { $0.date == selectedDate }
        return selected
    }
    
    private var selectedHourlyUsage: HourlyUsage? {
        guard let selectedDate = selectedDate else { return nil }
        let selected = filteredHourlyUsage.first { $0.hour == selectedDate }
        return selected
    }
    
    @ViewBuilder
    private func chartView() -> some View {
        Chart {
            if selectedPeriod == .today {
                ForEach(filteredHourlyUsage, id: \.hour) { hourly in
                    BarMark(
                        x: .value("Hour", hourly.hour),
                        y: .value("Cost", hourly.totalCost)
                    )
                    .foregroundStyle(Color.blue.gradient)
                }
            } else {
                ForEach(filteredDailyUsage, id: \.date) { daily in
                    BarMark(
                        x: .value("Date", daily.date),
                        y: .value("Cost", daily.totalCost)
                    )
                    .foregroundStyle(Color.blue.gradient)
                }
            }

            // Selection rule mark
            if let selectedDate = selectedDate {
                RuleMark(x: .value("Date", selectedDate))
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .annotation(position: .top, spacing: 0, overflowResolution: .init(
                        x: .fit(to: .chart),
                        y: .disabled
                    )) {
                        if selectedPeriod == .today {
                            if let selectedUsage = selectedHourlyUsage {
                                HourlyChartTooltip(hourlyUsage: selectedUsage)
                            } else {
                                Text("No selected")
                            }
                        } else {
                            if let selectedUsage = selectedDailyUsage {
                                ChartTooltip(dailyUsage: selectedUsage)
                            } else {
                                Text("No selected")
                            }
                        }
                    }
            }
        }
        .frame(height: 400)
        .chartXSelection(value: $selectedDate)
        .chartXScale(range: .plotDimension(padding: 0))
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let cost = value.as(Double.self) {
                        Text(String(format: "$%.2f", cost))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel(anchor: .topLeading) {
                    if let dateString = value.as(String.self) {
                        Text(formattedDate(dateString))
                    }
                }
            }
        }
    }
    
    var body: some View {
        let hasData = selectedPeriod == .today ? !filteredHourlyUsage.isEmpty : !filteredDailyUsage.isEmpty
        
        if !hasData {
            ContentUnavailableView(
                "No Data",
                systemImage: "chart.bar",
                description: Text("No usage data available for the selected period")
            )
            .frame(height: 200)
        } else {
            chartView()
        }
    }
    
    private func formattedDate(_ dateString: String) -> String {
        if selectedPeriod == .today {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH"
            
            if let date = formatter.date(from: dateString) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = "HH"
                return displayFormatter.string(from: date) + ":00"
            } else {
                return dateString
            }
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            if let date = formatter.date(from: dateString) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = selectedPeriod == .week ? "MMM dd" : "MM/dd"
                return displayFormatter.string(from: date)
            } else {
                return dateString
            }
        }
    }
}

// MARK: - Chart Tooltip

struct ChartTooltip: View {
    let dailyUsage: DailyUsage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formattedDateDetailed(dailyUsage.date))
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Cost: \(String(format: "$%.2f", dailyUsage.totalCost))")
                .font(.body)
            
            Text("Tokens: \(dailyUsage.totalTokens.formattedTokens())")
                .font(.body)
        }
        .padding(8)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func formattedDateDetailed(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "EEEE, MMM dd, yyyy"
            return displayFormatter.string(from: date)
        } else {
            return dateString
        }
    }
}

struct HourlyChartTooltip: View {
    let hourlyUsage: HourlyUsage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formattedHourDetailed(hourlyUsage.hour))
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Cost: \(String(format: "$%.2f", hourlyUsage.totalCost))")
                .font(.body)
            
            Text("Tokens: \(hourlyUsage.totalTokens.formattedTokens())")
                .font(.body)
        }
        .padding(8)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func formattedHourDetailed(_ hourString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH"
        
        if let date = formatter.date(from: hourString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "HH:mm"
            return displayFormatter.string(from: date)
        } else {
            return hourString
        }
    }
}

// MARK: - Chart Statistics

struct ChartStatistics: View {
    let filteredDailyUsage: [DailyUsage]
    let filteredHourlyUsage: [HourlyUsage]
    let selectedPeriod: TimePeriod
    
    private var maxCost: Double {
        if selectedPeriod == .today {
            return filteredHourlyUsage.map { $0.totalCost }.max() ?? 0.0
        } else {
            return filteredDailyUsage.map { $0.totalCost }.max() ?? 0.0
        }
    }
    
    private var totalCost: Double {
        if selectedPeriod == .today {
            return filteredHourlyUsage.reduce(0) { $0 + $1.totalCost }
        } else {
            return filteredDailyUsage.reduce(0) { $0 + $1.totalCost }
        }
    }
    
    private var averageCost: Double {
        if selectedPeriod == .today {
            return filteredHourlyUsage.isEmpty ? 0.0 : totalCost / Double(filteredHourlyUsage.count)
        } else {
            return filteredDailyUsage.isEmpty ? 0.0 : totalCost / Double(filteredDailyUsage.count)
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Cost")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "$%.2f", totalCost))
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(selectedPeriod == .today ? "Average/Hour" : "Average/Day")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "$%.2f", averageCost))
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(selectedPeriod == .today ? "Peak Hour" : "Peak Day")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "$%.2f", maxCost))
                    .font(.title3)
                    .fontWeight(.semibold)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Daily Usage List Section

struct DailyUsageListSection: View {
    let filteredDailyUsage: [DailyUsage]
    
    var body: some View {
        if !filteredDailyUsage.isEmpty {
            Section("Recent Daily Usage") {
                ForEach(filteredDailyUsage.prefix(7), id: \.date) { daily in
                    DailyUsageRow(daily: daily)
                }
            }
        }
    }
}

// MARK: - Main Usage Chart View

struct UsageChartView: View {
    let usage: UsageStatistics
    @State private var selectedPeriod: TimePeriod = .week
    
    private var filteredDailyUsage: [DailyUsage] {
        if selectedPeriod == .today {
            return []
        }
        
        let calendar = Calendar.current
        let today = Date()
        let daysAgo = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: today) ?? today
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let cutoffDate = dateFormatter.string(from: daysAgo)
        
        return usage.dailyUsage
            .filter { $0.date >= cutoffDate }
            .sorted { $0.date < $1.date }
    }
    
    private var filteredHourlyUsage: [HourlyUsage] {
        if selectedPeriod != .today {
            return []
        }
        
        let calendar = Calendar.current
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: today)
        
        return usage.hourlyUsage
            .filter { $0.hour.hasPrefix(todayString) }
            .sorted { $0.hour < $1.hour }
    }
    
    var body: some View {
        Form {
            Section(selectedPeriod == .today ? "Hourly Usage Chart" : "Daily Usage Chart") {
                TimePeriodSelector(selectedPeriod: $selectedPeriod)
                
                InteractiveChart(
                    filteredDailyUsage: filteredDailyUsage,
                    filteredHourlyUsage: filteredHourlyUsage,
                    selectedPeriod: selectedPeriod
                )
                .padding(.top, 20)
                
                ChartStatistics(
                    filteredDailyUsage: filteredDailyUsage,
                    filteredHourlyUsage: filteredHourlyUsage,
                    selectedPeriod: selectedPeriod
                )
            }
           
            DailyUsageListSection(filteredDailyUsage: filteredDailyUsage)
        }
        .formStyle(.grouped)
    }
}

#Preview {
    let sampleDaily = [
        DailyUsage(date: "2025-01-10"),
        DailyUsage(date: "2025-01-11"),
        DailyUsage(date: "2025-01-12")
    ]
    
    let sampleHourly = [
        HourlyUsage(hour: "2025-01-10 08"),
        HourlyUsage(hour: "2025-01-10 09"),
        HourlyUsage(hour: "2025-01-10 10")
    ]
    
    let sampleStats = UsageStatistics(
        totalCost: 10.0,
        totalTokens: 1000,
        totalSessions: 10,
        modelUsage: [],
        projectUsage: [],
        monthlyUsage: [],
        dailyUsage: sampleDaily,
        hourlyUsage: sampleHourly,
        dateRange: ("2025-01-10", "2025-01-12")
    )
    
    UsageChartView(usage: sampleStats)
}
