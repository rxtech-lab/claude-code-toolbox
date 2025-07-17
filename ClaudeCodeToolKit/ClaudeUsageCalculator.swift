import Foundation

class ClaudeUsageCalculator {
    
    // MARK: - Dependencies
    
    private let parser = JSONLParser()
    private let aggregator = UsageAggregator()
    private let costCalculator = CostCalculator()
    
    // MARK: - Error Types
    
    enum UsageCalculatorError: Error {
        case noDataFound
        case invalidDateFormat
        case processingError(String)
    }
    
    // MARK: - Main Usage Statistics
    
    func getUsageStatistics() throws -> UsageStatistics {
        let entries = try parser.parseAllJSONLFiles()
        guard !entries.isEmpty else {
            throw UsageCalculatorError.noDataFound
        }
        
        return aggregator.generateUsageStatistics(entries)
    }
    
    // MARK: - Usage by Month
    
    func getUsageByMonth(_ month: String) throws -> [MonthlyUsage] {
        let entries = try parser.parseAllJSONLFiles()
        let filteredEntries = parser.filterEntries(entries, byMonth: month)
        
        return aggregator.aggregateByMonth(filteredEntries)
    }
    
    func getUsageByMonthRange(start: String, end: String) throws -> [MonthlyUsage] {
        let entries = try parser.parseAllJSONLFiles()
        let filteredEntries = entries.filter { entry in
            let entryMonth = String(entry.timestamp.prefix(7))
            return entryMonth >= start && entryMonth <= end
        }
        
        return aggregator.aggregateByMonth(filteredEntries)
    }
    
    // MARK: - Usage by Project
    
    func getUsageByProject(_ projectPath: String) throws -> [ProjectUsage] {
        let entries = try parser.parseAllJSONLFiles()
        let filteredEntries = parser.filterEntries(entries, byProject: projectPath)
        
        return aggregator.aggregateByProject(filteredEntries)
    }
    
    func getAllProjectUsage() throws -> [ProjectUsage] {
        let entries = try parser.parseAllJSONLFiles()
        return aggregator.aggregateByProject(entries)
    }
    
    // MARK: - Usage by Model
    
    func getUsageByModel(_ model: String) throws -> [ModelUsage] {
        let entries = try parser.parseAllJSONLFiles()
        let filteredEntries = parser.filterEntries(entries, byModel: model)
        
        return aggregator.aggregateByModel(filteredEntries)
    }
    
    func getAllModelUsage() throws -> [ModelUsage] {
        let entries = try parser.parseAllJSONLFiles()
        return aggregator.aggregateByModel(entries)
    }
    
    // MARK: - Usage by Date Range
    
    func getUsageByDateRange(start: Date, end: Date) throws -> UsageStatistics {
        let entries = try parser.parseAllJSONLFiles()
        let filteredEntries = parser.filterEntries(entries, byDateRange: start, end: end)
        
        return aggregator.generateUsageStatistics(filteredEntries)
    }
    
    // MARK: - Daily Usage
    
    func getDailyUsage() throws -> [DailyUsage] {
        let entries = try parser.parseAllJSONLFiles()
        return aggregator.aggregateByDay(entries)
    }
    
    func getDailyUsageForMonth(_ month: String) throws -> [DailyUsage] {
        let entries = try parser.parseAllJSONLFiles()
        let filteredEntries = parser.filterEntries(entries, byMonth: month)
        
        return aggregator.aggregateByDay(filteredEntries)
    }
    
    // MARK: - Combined Filters
    
    func getUsageByProjectAndMonth(projectPath: String, month: String) throws -> UsageStatistics {
        let entries = try parser.parseAllJSONLFiles()
        let projectFiltered = parser.filterEntries(entries, byProject: projectPath)
        let monthFiltered = parser.filterEntries(projectFiltered, byMonth: month)
        
        return aggregator.generateUsageStatistics(monthFiltered)
    }
    
    func getUsageByModelAndMonth(model: String, month: String) throws -> UsageStatistics {
        let entries = try parser.parseAllJSONLFiles()
        let modelFiltered = parser.filterEntries(entries, byModel: model)
        let monthFiltered = parser.filterEntries(modelFiltered, byMonth: month)
        
        return aggregator.generateUsageStatistics(monthFiltered)
    }
    
    // MARK: - Summary Methods
    
    func getTotalSpending() throws -> Double {
        let stats = try getUsageStatistics()
        return stats.totalCost
    }
    
    func getTotalTokens() throws -> Int {
        let stats = try getUsageStatistics()
        return stats.totalTokens
    }
    
    func getTotalSessions() throws -> Int {
        let stats = try getUsageStatistics()
        return stats.totalSessions
    }
    
    func getTopProjects(limit: Int = 10) throws -> [ProjectUsage] {
        let projects = try getAllProjectUsage()
        return Array(projects.prefix(limit))
    }
    
    func getTopModels(limit: Int = 10) throws -> [ModelUsage] {
        let models = try getAllModelUsage()
        return Array(models.prefix(limit))
    }
    
    // MARK: - Utility Methods
    
    func getSupportedModels() -> [String] {
        return costCalculator.getSupportedModels()
    }
    
    func isModelSupported(_ model: String) -> Bool {
        return costCalculator.isModelSupported(model)
    }
    
    func getPricingInfo(for model: String) -> (input: Double, output: Double, cacheWrite: Double, cacheRead: Double)? {
        return costCalculator.getPricingInfo(for: model)
    }
    
    func discoverAvailableProjects() -> [String] {
        do {
            let entries = try parser.parseAllJSONLFiles()
            let uniqueProjects = Set(entries.map { $0.projectPath })
            return Array(uniqueProjects).sorted()
        } catch {
            return []
        }
    }
    
    func discoverAvailableModels() -> [String] {
        do {
            let entries = try parser.parseAllJSONLFiles()
            let uniqueModels = Set(entries.map { $0.model })
            return Array(uniqueModels).sorted()
        } catch {
            return []
        }
    }
    
    func discoverAvailableMonths() -> [String] {
        do {
            let entries = try parser.parseAllJSONLFiles()
            let uniqueMonths = Set(entries.map { String($0.timestamp.prefix(7)) })
            return Array(uniqueMonths).sorted(by: >)
        } catch {
            return []
        }
    }
}