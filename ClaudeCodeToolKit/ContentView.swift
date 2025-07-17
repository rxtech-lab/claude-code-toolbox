//
//  ContentView.swift
//  ClaudeCodeToolKit
//
//  Created by Qiwei Li on 7/17/25.
//

import AppKit
import SwiftUI

struct ContentView: View {
    @State private var usageData: UsageStatistics?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingPermissionAlert = false
    @State private var hasDirectoryAccess = false
    
    private let calculator = ClaudeUsageCalculator()
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack {
                        ProgressView("Loading usage data...")
                            .scaleEffect(1.2)
                        Text("Analyzing Claude usage...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                } else if let errorMessage = errorMessage {
                    ContentUnavailableView(
                        "Error Loading Data",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else if let usage = usageData {
                    UsageTabbedView(usage: usage)
                } else {
                    ContentUnavailableView(
                        "No Usage Data",
                        systemImage: "chart.bar",
                        description: Text("No Claude usage data found")
                    )
                }
            }
        }
        .refreshable {
            await loadUsageData()
        }
        .onAppear {
            Task {
                await loadUsageData()
            }
        }
    }
    
    private func loadUsageData() async {
        isLoading = true
        errorMessage = nil
       
        do {
            let stats = try calculator.getUsageStatistics()
            await MainActor.run {
                self.usageData = stats
                self.isLoading = false
            }
        } catch let error as ClaudeUsageCalculator.UsageCalculatorError {
            switch error {
            case .noDataFound:
                // request permission if no data found
                await MainActor.run {
                    self.showingPermissionAlert = true
                    self.isLoading = false
                }
                
            default:
                print("Error calculating usage: \(error)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        } catch {
            print("Error loading usage data: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

struct UsageTabbedView: View {
    let usage: UsageStatistics
    
    var body: some View {
        TabView {
            UsageTextView(usage: usage)
                .tabItem {
                    Image(systemName: "text.alignleft")
                    Text("Details")
                }
            
            UsageChartView(usage: usage)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Chart")
                }
                .padding()
        }
    }
}

struct UsageTextView: View {
    let usage: UsageStatistics
    
    var body: some View {
        Form {
            // Summary Section
            Section("Summary") {
                SummaryRow(
                    title: "Total Spent",
                    value: String(format: "$%.2f", usage.totalCost),
                    systemImage: "dollarsign.circle.fill",
                    color: .green
                )
                
                SummaryRow(
                    title: "Total Tokens",
                    value: usage.totalTokens.formattedTokens(),
                    systemImage: "textformat.123",
                    color: .blue
                )
                
                SummaryRow(
                    title: "Total Sessions",
                    value: usage.totalSessions.formatted(),
                    systemImage: "bubble.left.and.bubble.right.fill",
                    color: .orange
                )
                
                // Current Month Usage
                CurrentMonthSummaryRow(usage: usage)
            }
            
            // Top Models Section
            if !usage.modelUsage.isEmpty {
                Section("Top Models") {
                    ForEach(usage.modelUsage.prefix(5), id: \.model) { model in
                        ModelUsageRow(model: model)
                    }
                }
            }
            
            // Top Projects Section
            if !usage.projectUsage.isEmpty {
                Section("Top Projects") {
                    ForEach(usage.projectUsage.prefix(5), id: \.projectPath) { project in
                        ProjectUsageRow(project: project)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

struct CurrentMonthSummaryRow: View {
    let usage: UsageStatistics
    
    var currentMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
    
    var currentMonthUsage: MonthlyUsage? {
        let currentMonthKey = String(Date().description.prefix(7))
        return usage.monthlyUsage.first { $0.month == currentMonthKey }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(.purple)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("This Month (\(currentMonth))")
                    .font(.body)
                
                if let monthUsage = currentMonthUsage {
                    Text("\(monthUsage.totalTokens.formattedTokens()) tokens • \(monthUsage.sessionCount) sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("No usage this month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let monthUsage = currentMonthUsage {
                Text(String(format: "$%.2f", monthUsage.totalCost))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            } else {
                Text("$0.00")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProjectUsageRow: View {
    let project: ProjectUsage
    
    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(project.projectName)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("\(project.totalTokens.formattedTokens()) tokens • \(project.sessionCount) sessions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "$%.2f", project.totalCost))
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

struct ModelUsageRow: View {
    let model: ModelUsage
    
    var modelDisplayName: String {
        if model.model.contains("sonnet") {
            return "Claude Sonnet"
        } else if model.model.contains("opus") {
            return "Claude Opus"
        } else if model.model.contains("haiku") {
            return "Claude Haiku"
        } else {
            return model.model
        }
    }
    
    var modelIcon: String {
        if model.model.contains("sonnet") {
            return "brain.head.profile"
        } else if model.model.contains("opus") {
            return "sparkles"
        } else if model.model.contains("haiku") {
            return "leaf.fill"
        } else {
            return "cpu"
        }
    }
    
    var modelColor: Color {
        if model.model.contains("sonnet") {
            return .indigo
        } else if model.model.contains("opus") {
            return .purple
        } else if model.model.contains("haiku") {
            return .green
        } else {
            return .gray
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: modelIcon)
                .foregroundColor(modelColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(modelDisplayName)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("\(model.totalTokens.formattedTokens()) tokens • \(model.sessionCount) sessions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "$%.2f", model.totalCost))
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

struct DailyUsageRow: View {
    let daily: DailyUsage
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: daily.date) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM dd"
            return displayFormatter.string(from: date)
        } else {
            return daily.date
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "calendar.circle.fill")
                .foregroundColor(.orange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(formattedDate)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("\(daily.totalTokens.formattedTokens()) tokens • \(daily.modelsUsed.count) models")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "$%.2f", daily.totalCost))
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
