import Foundation

// Example usage of ClaudeUsageCalculator
class UsageExample {
    
    static func runExample() {
        let calculator = ClaudeUsageCalculator()
        
        do {
            // Get overall usage statistics
            print("=== Overall Usage Statistics ===")
            let stats = try calculator.getUsageStatistics()
            print("Total cost: $\(String(format: "%.4f", stats.totalCost))")
            print("Total tokens: \(stats.totalTokens)")
            print("Total sessions: \(stats.totalSessions)")
            print("Date range: \(stats.dateRange.start) to \(stats.dateRange.end)")
            
            // Get usage by model
            print("\n=== Usage by Model ===")
            let modelUsage = try calculator.getAllModelUsage()
            for model in modelUsage.prefix(3) {
                print("\(model.model):")
                print("  Cost: $\(String(format: "%.4f", model.totalCost))")
                print("  Tokens: \(model.totalTokens)")
                print("  Sessions: \(model.sessionCount)")
            }
            
            // Get usage by project
            print("\n=== Top Projects by Cost ===")
            let projectUsage = try calculator.getTopProjects(limit: 3)
            for project in projectUsage {
                print("\(project.projectName):")
                print("  Cost: $\(String(format: "%.4f", project.totalCost))")
                print("  Tokens: \(project.totalTokens)")
                print("  Sessions: \(project.sessionCount)")
                print("  Last used: \(project.lastUsed)")
            }
            
            // Get monthly usage
            print("\n=== Monthly Usage ===")
            let monthlyUsage = try calculator.getUsageByMonthRange(start: "2025-01", end: "2025-12")
            for month in monthlyUsage.prefix(3) {
                print("\(month.month):")
                print("  Cost: $\(String(format: "%.4f", month.totalCost))")
                print("  Tokens: \(month.totalTokens)")
                print("  Sessions: \(month.sessionCount)")
                print("  Models used: \(month.modelsUsed.joined(separator: ", "))")
            }
            
            // Get daily usage for current month
            print("\n=== Daily Usage (Current Month) ===")
            let currentMonth = DateFormatter().string(from: Date()).prefix(7)
            let dailyUsage = try calculator.getDailyUsageForMonth(String(currentMonth))
            for day in dailyUsage.prefix(5) {
                print("\(day.date):")
                print("  Cost: $\(String(format: "%.4f", day.totalCost))")
                print("  Tokens: \(day.totalTokens)")
                print("  Models: \(day.modelsUsed.joined(separator: ", "))")
            }
            
            // Get available projects and models
            print("\n=== Available Data ===")
            let availableProjects = calculator.discoverAvailableProjects()
            let availableModels = calculator.discoverAvailableModels()
            let availableMonths = calculator.discoverAvailableMonths()
            
            print("Available projects: \(availableProjects.count)")
            print("Available models: \(availableModels.joined(separator: ", "))")
            print("Available months: \(availableMonths.joined(separator: ", "))")
            
            // Get pricing information
            print("\n=== Pricing Information ===")
            let supportedModels = calculator.getSupportedModels()
            for model in supportedModels {
                if let pricing = calculator.getPricingInfo(for: model) {
                    print("\(model):")
                    print("  Input: $\(pricing.input)/M tokens")
                    print("  Output: $\(pricing.output)/M tokens")
                    print("  Cache Write: $\(pricing.cacheWrite)/M tokens")
                    print("  Cache Read: $\(pricing.cacheRead)/M tokens")
                }
            }
            
        } catch {
            print("Error: \(error)")
        }
    }
}

// Example of filtering usage
class FilteredUsageExample {
    
    static func runFilteredExample() {
        let calculator = ClaudeUsageCalculator()
        
        do {
            // Get usage for specific project and month
            print("=== Filtered Usage Example ===")
            let projectPath = "/Users/test/project1"
            let month = "2025-01"
            
            let filteredStats = try calculator.getUsageByProjectAndMonth(
                projectPath: projectPath,
                month: month
            )
            
            print("Usage for project \(projectPath) in \(month):")
            print("Total cost: $\(String(format: "%.4f", filteredStats.totalCost))")
            print("Total tokens: \(filteredStats.totalTokens)")
            print("Total sessions: \(filteredStats.totalSessions)")
            
            // Get usage for specific model and month
            let model = "claude-sonnet-4"
            let modelMonthStats = try calculator.getUsageByModelAndMonth(
                model: model,
                month: month
            )
            
            print("\nUsage for model \(model) in \(month):")
            print("Total cost: $\(String(format: "%.4f", modelMonthStats.totalCost))")
            print("Total tokens: \(modelMonthStats.totalTokens)")
            print("Total sessions: \(modelMonthStats.totalSessions)")
            
            // Get usage by date range
            let dateFormatter = ISO8601DateFormatter()
            let startDate = dateFormatter.date(from: "2025-01-01T00:00:00Z")!
            let endDate = dateFormatter.date(from: "2025-01-31T23:59:59Z")!
            
            let rangeStats = try calculator.getUsageByDateRange(
                start: startDate,
                end: endDate
            )
            
            print("\nUsage for January 2025:")
            print("Total cost: $\(String(format: "%.4f", rangeStats.totalCost))")
            print("Total tokens: \(rangeStats.totalTokens)")
            print("Total sessions: \(rangeStats.totalSessions)")
            
        } catch {
            print("Error: \(error)")
        }
    }
}

// Example of using individual components
class ComponentExample {
    
    static func runComponentExample() {
        print("=== Component Usage Example ===")
        
        // Example usage data
        let mockUsage = UsageData(
            inputTokens: 1000,
            outputTokens: 500,
            cacheCreationInputTokens: 200,
            cacheReadInputTokens: 100
        )
        
        // Cost calculation
        let costCalculator = CostCalculator()
        let sonnetCost = costCalculator.calculateCost(for: "claude-sonnet-4", usage: mockUsage)
        let opusCost = costCalculator.calculateCost(for: "claude-opus-4", usage: mockUsage)
        let totalTokens = costCalculator.calculateTotalTokens(usage: mockUsage)
        
        print("Cost for Sonnet 4: $\(String(format: "%.6f", sonnetCost))")
        print("Cost for Opus 4: $\(String(format: "%.6f", opusCost))")
        print("Total tokens: \(totalTokens)")
        
        // Model support check
        print("\nSupported models:")
        let supportedModels = costCalculator.getSupportedModels()
        for model in supportedModels {
            print("- \(model): \(costCalculator.isModelSupported(model))")
        }
        
        // JSONL parsing example
        let parser = JSONLParser()
        let mockJSONL = """
        {"model": "claude-sonnet-4", "usage": {"input_tokens": 1000, "output_tokens": 500}, "timestamp": "2025-01-15T10:30:00Z", "project_path": "/Users/test/project1"}
        """
        
        do {
            let entries = try parser.parseJSONLContent(mockJSONL)
            print("\nParsed \(entries.count) entries from JSONL")
            if let first = entries.first {
                print("First entry: \(first.model) - \(first.usage?.inputTokens ?? 0) input tokens")
            }
        } catch {
            print("JSONL parsing error: \(error)")
        }
    }
}