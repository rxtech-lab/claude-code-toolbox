import Foundation

class UsageAggregator {
    
    private let costCalculator = CostCalculator()
    
    // MARK: - Timezone Conversion Helper
    
    private func convertUTCTimestampToLocalHour(_ utcTimestamp: String) -> String {
        // Parse UTC timestamp (format: "2025-07-18T02:48:03.470Z")
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let utcDate = iso8601Formatter.date(from: utcTimestamp) else {
            // Fallback to simple prefix extraction if parsing fails
            return String(utcTimestamp.prefix(13))
        }
        
        // Convert to local timezone and format as "YYYY-MM-DDTHH"
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH"
        localFormatter.timeZone = TimeZone.current
        
        return localFormatter.string(from: utcDate)
    }
    
    private func convertUTCTimestampToLocalDate(_ utcTimestamp: String) -> String {
        // Parse UTC timestamp (format: "2025-07-18T02:48:03.470Z")
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let utcDate = iso8601Formatter.date(from: utcTimestamp) else {
            // Fallback to simple prefix extraction if parsing fails
            return String(utcTimestamp.prefix(10))
        }
        
        // Convert to local timezone and format as "YYYY-MM-DD"
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd"
        localFormatter.timeZone = TimeZone.current
        
        return localFormatter.string(from: utcDate)
    }
    
    // MARK: - Aggregation by Model
    
    func aggregateByModel(_ entries: [JSONLEntry]) -> [ModelUsage] {
        var modelStats: [String: ModelUsage] = [:]
        
        for entry in entries {
            guard let usage = entry.usage else { continue }
            
            let cost = costCalculator.calculateCost(for: entry.model, usage: usage)
            let totalTokens = costCalculator.calculateTotalTokens(usage: usage)
            
            if modelStats[entry.model] == nil {
                modelStats[entry.model] = ModelUsage(model: entry.model)
            }
            
            var modelStat = modelStats[entry.model]!
            modelStat.totalCost += cost
            modelStat.inputTokens += usage.inputTokens ?? 0
            modelStat.outputTokens += usage.outputTokens ?? 0
            modelStat.cacheCreationTokens += usage.cacheCreationInputTokens ?? 0
            modelStat.cacheReadTokens += usage.cacheReadInputTokens ?? 0
            modelStat.totalTokens = modelStat.inputTokens + modelStat.outputTokens + modelStat.cacheCreationTokens + modelStat.cacheReadTokens
            modelStat.sessionCount += 1
            
            modelStats[entry.model] = modelStat
        }
        
        return Array(modelStats.values).sorted { $0.totalCost > $1.totalCost }
    }
    
    // MARK: - Aggregation by Project
    
    func aggregateByProject(_ entries: [JSONLEntry]) -> [ProjectUsage] {
        var projectStats: [String: ProjectUsage] = [:]
        
        for entry in entries {
            guard let usage = entry.usage else { continue }
            
            let cost = costCalculator.calculateCost(for: entry.model, usage: usage)
            let totalTokens = costCalculator.calculateTotalTokens(usage: usage)
            
            if projectStats[entry.projectPath] == nil {
                projectStats[entry.projectPath] = ProjectUsage(projectPath: entry.projectPath)
            }
            
            var projectStat = projectStats[entry.projectPath]!
            projectStat.totalCost += cost
            projectStat.totalTokens += totalTokens
            projectStat.sessionCount += 1
            
            // Update last used timestamp
            if entry.timestamp > projectStat.lastUsed {
                projectStat.lastUsed = entry.timestamp
            }
            
            projectStats[entry.projectPath] = projectStat
        }
        
        return Array(projectStats.values).sorted { $0.totalCost > $1.totalCost }
    }
    
    // MARK: - Aggregation by Month
    
    func aggregateByMonth(_ entries: [JSONLEntry]) -> [MonthlyUsage] {
        var monthlyStats: [String: MonthlyUsage] = [:]
        
        for entry in entries {
            guard let usage = entry.usage else { continue }
            
            let cost = costCalculator.calculateCost(for: entry.model, usage: usage)
            let totalTokens = costCalculator.calculateTotalTokens(usage: usage)
            
            // Extract month from timestamp (YYYY-MM format)
            let month = String(entry.timestamp.prefix(7))
            
            if monthlyStats[month] == nil {
                monthlyStats[month] = MonthlyUsage(month: month)
            }
            
            var monthlyStat = monthlyStats[month]!
            monthlyStat.totalCost += cost
            monthlyStat.totalTokens += totalTokens
            monthlyStat.sessionCount += 1
            
            // Track unique models used
            if !monthlyStat.modelsUsed.contains(entry.model) {
                monthlyStat.modelsUsed.append(entry.model)
            }
            
            monthlyStats[month] = monthlyStat
        }
        
        return Array(monthlyStats.values).sorted { $0.month > $1.month }
    }
    
    // MARK: - Aggregation by Day
    
    func aggregateByDay(_ entries: [JSONLEntry]) -> [DailyUsage] {
        var dailyStats: [String: DailyUsage] = [:]
        
        for entry in entries {
            guard let usage = entry.usage else { continue }
            
            let cost = costCalculator.calculateCost(for: entry.model, usage: usage)
            let totalTokens = costCalculator.calculateTotalTokens(usage: usage)
            
            // Convert UTC timestamp to local timezone date
            let date = convertUTCTimestampToLocalDate(entry.timestamp)
            
            if dailyStats[date] == nil {
                dailyStats[date] = DailyUsage(date: date)
            }
            
            var dailyStat = dailyStats[date]!
            dailyStat.totalCost += cost
            dailyStat.totalTokens += totalTokens
            
            // Track unique models used
            if !dailyStat.modelsUsed.contains(entry.model) {
                dailyStat.modelsUsed.append(entry.model)
            }
            
            dailyStats[date] = dailyStat
        }
        
        return Array(dailyStats.values).sorted { $0.date > $1.date }
    }
    
    // MARK: - Aggregation by Hour
    
    func aggregateByHour(_ entries: [JSONLEntry]) -> [HourlyUsage] {
        var hourlyStats: [String: HourlyUsage] = [:]
        
        for entry in entries {
            guard let usage = entry.usage else { continue }
            
            let cost = costCalculator.calculateCost(for: entry.model, usage: usage)
            let totalTokens = costCalculator.calculateTotalTokens(usage: usage)
            
            // Convert UTC timestamp to local timezone hour
            let hour = convertUTCTimestampToLocalHour(entry.timestamp)
            
            if hourlyStats[hour] == nil {
                hourlyStats[hour] = HourlyUsage(hour: hour)
            }
            
            var hourlyStat = hourlyStats[hour]!
            hourlyStat.totalCost += cost
            hourlyStat.totalTokens += totalTokens
            
            // Track unique models used
            if !hourlyStat.modelsUsed.contains(entry.model) {
                hourlyStat.modelsUsed.append(entry.model)
            }
            
            hourlyStats[hour] = hourlyStat
        }
        
        return Array(hourlyStats.values).sorted { $0.hour > $1.hour }
    }
    
    // MARK: - Overall Statistics
    
    func calculateOverallStats(_ entries: [JSONLEntry]) -> (totalCost: Double, totalTokens: Int, totalSessions: Int) {
        var totalCost: Double = 0.0
        var totalTokens: Int = 0
        var totalSessions: Int = 0
        
        for entry in entries {
            guard let usage = entry.usage else { continue }
            
            let cost = costCalculator.calculateCost(for: entry.model, usage: usage)
            let tokens = costCalculator.calculateTotalTokens(usage: usage)
            
            totalCost += cost
            totalTokens += tokens
            totalSessions += 1
        }
        
        return (totalCost, totalTokens, totalSessions)
    }
    
    // MARK: - Date Range Calculation
    
    func calculateDateRange(_ entries: [JSONLEntry]) -> (start: String, end: String) {
        guard !entries.isEmpty else { return ("", "") }
        
        let timestamps = entries.map { $0.timestamp }.sorted()
        return (timestamps.first ?? "", timestamps.last ?? "")
    }
    
    // MARK: - Comprehensive Usage Statistics
    
    func generateUsageStatistics(_ entries: [JSONLEntry]) -> UsageStatistics {
        let modelUsage = aggregateByModel(entries)
        let projectUsage = aggregateByProject(entries)
        let monthlyUsage = aggregateByMonth(entries)
        let dailyUsage = aggregateByDay(entries)
        let hourlyUsage = aggregateByHour(entries)
        let overallStats = calculateOverallStats(entries)
        let dateRange = calculateDateRange(entries)
        
        return UsageStatistics(
            totalCost: overallStats.totalCost,
            totalTokens: overallStats.totalTokens,
            totalSessions: overallStats.totalSessions,
            modelUsage: modelUsage,
            projectUsage: projectUsage,
            monthlyUsage: monthlyUsage,
            dailyUsage: dailyUsage,
            hourlyUsage: hourlyUsage,
            dateRange: dateRange
        )
    }
}