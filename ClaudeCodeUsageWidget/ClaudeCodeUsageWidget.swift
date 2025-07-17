//
//  ClaudeCodeUsageWidget.swift
//  ClaudeCodeUsageWidget
//
//  Created by Qiwei Li on 7/17/25.
//

import SwiftUI
import WidgetKit

struct Provider: AppIntentTimelineProvider {
    private let calculator = ClaudeUsageCalculator()
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), usageData: nil)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let usageData = await loadUsageData()
        return SimpleEntry(date: Date(), configuration: configuration, usageData: usageData)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let usageData = await loadUsageData()
        let currentDate = Date()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        
        let entry = SimpleEntry(date: currentDate, configuration: configuration, usageData: usageData)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func loadUsageData() async -> UsageDisplayData? {
        do {
            let stats = try calculator.getUsageStatistics()
            let currentMonth = getCurrentMonth()
            let monthlyStats = try calculator.getUsageByMonth(currentMonth)
            let topProjects = try calculator.getTopProjects(limit: 3)
            let topModels = try calculator.getTopModels(limit: 3)
            
            return UsageDisplayData(
                totalCost: stats.totalCost,
                totalTokens: stats.totalTokens,
                totalSessions: stats.totalSessions,
                currentMonthCost: monthlyStats.first?.totalCost ?? 0.0,
                currentMonthTokens: monthlyStats.first?.totalTokens ?? 0,
                topProjects: topProjects,
                topModels: topModels
            )
        } catch {
            return nil
        }
    }
    
    private func getCurrentMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }
}

struct UsageDisplayData {
    let totalCost: Double
    let totalTokens: Int
    let totalSessions: Int
    let currentMonthCost: Double
    let currentMonthTokens: Int
    let topProjects: [ProjectUsage]
    let topModels: [ModelUsage]
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let usageData: UsageDisplayData?
}

struct ClaudeCodeUsageWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        if let usageData = entry.usageData {
            VStack(alignment: .leading, spacing: 8) {
                // Total Usage
                UsageMetricRow(
                    title: "Total Usage",
                    value: String(format: "$%.2f", usageData.totalCost),
                    subtitle: "\(usageData.totalTokens) tokens"
                )
                
                // Monthly Usage
                UsageMetricRow(
                    title: "This Month",
                    value: String(format: "$%.2f", usageData.currentMonthCost),
                    subtitle: "\(usageData.currentMonthTokens) tokens"
                )
                
                // Top Projects
                if !usageData.topProjects.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Top Projects")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(usageData.topProjects.prefix(2), id: \.projectPath) { project in
                            HStack {
                                Text(project.projectName)
                                    .font(.caption2)
                                    .lineLimit(1)
                                Spacer()
                                Text(String(format: "$%.2f", project.totalCost))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Top Models
                if !usageData.topModels.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Top Models")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(usageData.topModels.prefix(2), id: \.model) { model in
                            HStack {
                                Text(model.model)
                                    .font(.caption2)
                                    .lineLimit(1)
                                Spacer()
                                Text(String(format: "$%.2f", model.totalCost))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
        } else {
            VStack {
                Image(systemName: "chart.bar")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("No usage data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

struct UsageMetricRow: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct ClaudeCodeUsageWidget: Widget {
    let kind: String = "ClaudeCodeUsageWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            ClaudeCodeUsageWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Claude Usage")
        .description("View your Claude API usage statistics")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
