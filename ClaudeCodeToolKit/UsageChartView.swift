import Charts
import SwiftUI

enum TimePeriod: String, CaseIterable {
    case week = "7 days"
    case twoWeeks = "14 days"
    case month = "30 days"
    
    var days: Int {
        switch self {
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
    let selectedPeriod: TimePeriod
    @State private var selectedDate: String?
    
    private var selectedDailyUsage: DailyUsage? {
        guard let selectedDate = selectedDate else { return nil }
        let selected = filteredDailyUsage.first { $0.date == selectedDate }
        return selected
    }
    
    @ViewBuilder
    private func chartView() -> some View {
        Chart {
            ForEach(filteredDailyUsage, id: \.date) { daily in
                BarMark(
                    x: .value("Date", daily.date),
                    y: .value("Cost", daily.totalCost)
                )
                .foregroundStyle(Color.blue.gradient)
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
                        if let selectedUsage = selectedDailyUsage {
                            ChartTooltip(dailyUsage: selectedUsage)
                        } else {
                            Text("No selected")
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
                            .font(.caption)
                            .rotationEffect(.degrees(-45))
                    }
                }
            }
        }
    }
    
    var body: some View {
        if filteredDailyUsage.isEmpty {
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

// MARK: - Chart Statistics

struct ChartStatistics: View {
    let filteredDailyUsage: [DailyUsage]
    
    private var maxCost: Double {
        filteredDailyUsage.map { $0.totalCost }.max() ?? 0.0
    }
    
    private var totalCost: Double {
        filteredDailyUsage.reduce(0) { $0 + $1.totalCost }
    }
    
    private var averageCost: Double {
        filteredDailyUsage.isEmpty ? 0.0 : totalCost / Double(filteredDailyUsage.count)
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
                Text("Average/Day")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "$%.2f", averageCost))
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Peak Day")
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
    
    var body: some View {
        Form {
            Section("Daily Usage Chart") {
                TimePeriodSelector(selectedPeriod: $selectedPeriod)
                
                InteractiveChart(
                    filteredDailyUsage: filteredDailyUsage,
                    selectedPeriod: selectedPeriod
                )
                .padding(.top, 20)
                
                ChartStatistics(filteredDailyUsage: filteredDailyUsage)
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
    
    let sampleStats = UsageStatistics(
        totalCost: 10.0,
        totalTokens: 1000,
        totalSessions: 10,
        modelUsage: [],
        projectUsage: [],
        monthlyUsage: [],
        dailyUsage: sampleDaily,
        dateRange: ("2025-01-10", "2025-01-12")
    )
    
    UsageChartView(usage: sampleStats)
}
