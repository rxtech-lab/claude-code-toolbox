import SwiftUI

enum MenuBarDisplayType: String, CaseIterable {
    case totalTokens = "Total Tokens"
    case monthlyCoast = "This Month Cost"
    case totalCoast = "Total Cost"
    case lastHourCost = "Last Hour Cost"
    
    var displayName: String {
        return rawValue
    }
}

class MenuBarManager: ObservableObject {
    private var calculator: ClaudeUsageCalculator
    private var refreshTimer: Timer?
    @Published var displayType: MenuBarDisplayType = .totalTokens
    @Published var stats: UsageStatistics?
    @Published var currentDisplayValue: String = ""
    @Published var lastRefreshTime: Date?
    
    private let displayTypeKey = "MenuBarDisplayType"
    
    init() {
        self.calculator = ClaudeUsageCalculator()
        loadDisplayType()
        startRefreshTimer()
        refreshData()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    func refreshData() {
        Task {
            do {
                let newStats = try calculator.getUsageStatistics()
                await MainActor.run {
                    stats = newStats
                    lastRefreshTime = Date()
                    updateDisplayValue()
                }
            } catch {
                await MainActor.run {
                    currentDisplayValue = "Error"
                }
            }
        }
    }
    
    func setDisplayType(_ type: MenuBarDisplayType) {
        displayType = type
        saveDisplayType()
        updateDisplayValue()
    }
    
    private func updateDisplayValue() {
        guard let stats = stats else {
            currentDisplayValue = "Loading..."
            return
        }
        
        switch displayType {
        case .totalTokens:
            currentDisplayValue = "\(stats.totalTokens.formattedTokens())"
        case .totalCoast:
            currentDisplayValue = "$\(String(format: "%.2f", stats.totalCost))"
        case .monthlyCoast:
            let monthlyCoast = getCurrentMonthCost()
            currentDisplayValue = "$\(String(format: "%.2f", monthlyCoast))"
        case .lastHourCost:
            let lastHourCost = getLastHourCost()
            currentDisplayValue = "$\(String(format: "%.2f", lastHourCost))"
        }
    }
    
    private func getCurrentMonthCost() -> Double {
        guard let stats = stats else { return 0.0 }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let currentMonth = dateFormatter.string(from: Date())
        
        let monthlyUsage = stats.monthlyUsage.first { $0.month == currentMonth }
        return monthlyUsage?.totalCost ?? 0.0
    }
    
    private func getLastHourCost() -> Double {
        guard let stats = stats else { return 0.0 }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH"
        let lastHour = dateFormatter.string(from: Date().addingTimeInterval(-3600))
        
        let hourlyUsage = stats.hourlyUsage.first { $0.hour == lastHour }
        return hourlyUsage?.totalCost ?? 0.0
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            self.refreshData()
        }
    }
    
    private func loadDisplayType() {
        if let savedType = UserDefaults.standard.string(forKey: displayTypeKey),
           let type = MenuBarDisplayType(rawValue: savedType)
        {
            displayType = type
        }
    }
    
    private func saveDisplayType() {
        UserDefaults.standard.set(displayType.rawValue, forKey: displayTypeKey)
    }
}
