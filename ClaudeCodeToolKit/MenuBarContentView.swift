import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var menuBarManager: MenuBarManager
    @State private var isRefreshing = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Menu("Display Type") {
                    ForEach(MenuBarDisplayType.allCases, id: \.self) { type in
                        Button(action: {
                            menuBarManager.setDisplayType(type)
                        }) {
                            HStack {
                                Text(type.displayName)
                                Spacer()
                                if menuBarManager.displayType == type {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
               
                if let lastRefresh = menuBarManager.lastRefreshTime {
                    Text("Last: \(lastRefresh, formatter: timeFormatter)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Statistics
            if let stats = menuBarManager.stats {
                VStack(spacing: 4) {
                    HStack {
                        Text("Total Cost:")
                        Text("$\(String(format: "%.2f", stats.totalCost))")
                    }
                
                    HStack {
                        Text("This Month:")
                     
                        Text("$\(String(format: "%.2f", getCurrentMonthCost(from: stats)))")
                    }
                    
                    HStack {
                        Text("Last Hour:")
                        Text("$\(String(format: "%.2f", getLastHourCost(from: stats)))")
                    }
                   
                    HStack {
                        Text("Total Tokens:")
                      
                        Text(stats.totalTokens.formattedTokens())
                    }
                    
                    HStack {
                        Text("Total Sessions:")
                      
                        Text("\(stats.totalSessions)")
                    }
                }
            } else {
                Text("Loading...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Actions
            VStack(spacing: 4) {
                Button(action: {
                    isRefreshing = true
                    menuBarManager.refreshData()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isRefreshing = false
                    }
                }) {
                    HStack {
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 12, height: 12)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12))
                        }
                        Text("Refresh Data")
                            .font(.system(size: 12))
                    }
                }
                .keyboardShortcut("r")
                .disabled(isRefreshing)
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
                .font(.system(size: 12))
            }
        }
        .padding()
        .frame(width: 240)
        .onAppear {
            menuBarManager.refreshData()
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    private func getCurrentMonthCost(from stats: UsageStatistics) -> Double {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let currentMonth = dateFormatter.string(from: Date())
        
        let monthlyUsage = stats.monthlyUsage.first { $0.month == currentMonth }
        return monthlyUsage?.totalCost ?? 0.0
    }
    
    private func getLastHourCost(from stats: UsageStatistics) -> Double {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH"
        let lastHour = dateFormatter.string(from: Date().addingTimeInterval(-3600))
        
        let hourlyUsage = stats.hourlyUsage.first { $0.hour == lastHour }
        return hourlyUsage?.totalCost ?? 0.0
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    MenuBarContentView(menuBarManager: MenuBarManager())
}
