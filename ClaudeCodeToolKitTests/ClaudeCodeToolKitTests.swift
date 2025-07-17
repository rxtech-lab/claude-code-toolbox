//
//  ClaudeCodeToolKitTests.swift
//  ClaudeCodeToolKitTests
//
//  Created by Qiwei Li on 7/17/25.
//

import Testing
import Foundation
@testable import ClaudeCodeToolKit

struct ClaudeCodeToolKitTests {
    
    // MARK: - Mock Data
    
    private let mockUsageData = UsageData(
        inputTokens: 1000,
        outputTokens: 500,
        cacheCreationInputTokens: 200,
        cacheReadInputTokens: 100
    )
    
    private let mockJSONLContent = """
    {"model": "claude-sonnet-4", "usage": {"input_tokens": 1000, "output_tokens": 500, "cache_creation_input_tokens": 200, "cache_read_input_tokens": 100}, "timestamp": "2025-01-15T10:30:00Z", "project_path": "/Users/test/project1"}
    {"model": "claude-opus-4", "usage": {"input_tokens": 2000, "output_tokens": 1000, "cache_creation_input_tokens": 400, "cache_read_input_tokens": 200}, "timestamp": "2025-01-16T14:45:00Z", "project_path": "/Users/test/project2"}
    {"model": "claude-sonnet-4", "usage": {"input_tokens": 1500, "output_tokens": 750, "cache_creation_input_tokens": 300, "cache_read_input_tokens": 150}, "timestamp": "2025-02-01T09:15:00Z", "project_path": "/Users/test/project1"}
    """
    
    // MARK: - Cost Calculator Tests
    
    @Test func testCostCalculationForSonnet4() async throws {
        let calculator = CostCalculator()
        let cost = calculator.calculateCost(for: "claude-sonnet-4", usage: mockUsageData)
        
        // Expected: (1000 * 3.00 + 500 * 15.00 + 200 * 3.75 + 100 * 0.30) / 1,000,000
        // = (3000 + 7500 + 750 + 30) / 1,000,000 = 11,280 / 1,000,000 = 0.01128
        let expected = 0.01128
        #expect(abs(cost - expected) < 0.00001)
    }
    
    @Test func testCostCalculationForOpus4() async throws {
        let calculator = CostCalculator()
        let cost = calculator.calculateCost(for: "claude-opus-4", usage: mockUsageData)
        
        // Expected: (1000 * 15.00 + 500 * 75.00 + 200 * 18.75 + 100 * 1.50) / 1,000,000
        // = (15000 + 37500 + 3750 + 150) / 1,000,000 = 56,400 / 1,000,000 = 0.0564
        let expected = 0.0564
        #expect(abs(cost - expected) < 0.00001)
    }
    
    @Test func testCostCalculationForUnsupportedModel() async throws {
        let calculator = CostCalculator()
        let cost = calculator.calculateCost(for: "unknown-model", usage: mockUsageData)
        
        #expect(cost == 0.0)
    }
    
    @Test func testTotalTokensCalculation() async throws {
        let calculator = CostCalculator()
        let totalTokens = calculator.calculateTotalTokens(usage: mockUsageData)
        
        // Expected: 1000 + 500 + 200 + 100 = 1800
        #expect(totalTokens == 1800)
    }
    
    @Test func testSupportedModels() async throws {
        let calculator = CostCalculator()
        let supportedModels = calculator.getSupportedModels()
        
        #expect(supportedModels.contains("sonnet-4"))
        #expect(supportedModels.contains("opus-4"))
        #expect(calculator.isModelSupported("claude-sonnet-4"))
        #expect(calculator.isModelSupported("claude-opus-4"))
        #expect(!calculator.isModelSupported("unknown-model"))
    }
    
    // MARK: - JSONL Parser Tests
    
    @Test func testJSONLContentParsing() async throws {
        let parser = JSONLParser()
        let entries = try parser.parseJSONLContent(mockJSONLContent)
        
        #expect(entries.count == 3)
        
        let firstEntry = entries[0]
        #expect(firstEntry.model == "claude-sonnet-4")
        #expect(firstEntry.usage?.inputTokens == 1000)
        #expect(firstEntry.usage?.outputTokens == 500)
        #expect(firstEntry.timestamp == "2025-01-15T10:30:00Z")
        #expect(firstEntry.projectPath == "/Users/test/project1")
    }
    
    @Test func testFilterEntriesByProject() async throws {
        let parser = JSONLParser()
        let entries = try parser.parseJSONLContent(mockJSONLContent)
        
        let project1Entries = parser.filterEntries(entries, byProject: "/Users/test/project1")
        #expect(project1Entries.count == 2)
        
        let project2Entries = parser.filterEntries(entries, byProject: "/Users/test/project2")
        #expect(project2Entries.count == 1)
    }
    
    @Test func testFilterEntriesByModel() async throws {
        let parser = JSONLParser()
        let entries = try parser.parseJSONLContent(mockJSONLContent)
        
        let sonnetEntries = parser.filterEntries(entries, byModel: "claude-sonnet-4")
        #expect(sonnetEntries.count == 2)
        
        let opusEntries = parser.filterEntries(entries, byModel: "claude-opus-4")
        #expect(opusEntries.count == 1)
    }
    
    @Test func testFilterEntriesByMonth() async throws {
        let parser = JSONLParser()
        let entries = try parser.parseJSONLContent(mockJSONLContent)
        
        let januaryEntries = parser.filterEntries(entries, byMonth: "2025-01")
        #expect(januaryEntries.count == 2)
        
        let februaryEntries = parser.filterEntries(entries, byMonth: "2025-02")
        #expect(februaryEntries.count == 1)
    }
    
    // MARK: - Usage Aggregator Tests
    
    @Test func testAggregateByModel() async throws {
        let parser = JSONLParser()
        let aggregator = UsageAggregator()
        let entries = try parser.parseJSONLContent(mockJSONLContent)
        
        let modelUsage = aggregator.aggregateByModel(entries)
        
        #expect(modelUsage.count == 2)
        
        let sonnetUsage = modelUsage.first { $0.model == "claude-sonnet-4" }
        #expect(sonnetUsage != nil)
        #expect(sonnetUsage!.sessionCount == 2)
        #expect(sonnetUsage!.inputTokens == 2500) // 1000 + 1500
        #expect(sonnetUsage!.outputTokens == 1250) // 500 + 750
        
        let opusUsage = modelUsage.first { $0.model == "claude-opus-4" }
        #expect(opusUsage != nil)
        #expect(opusUsage!.sessionCount == 1)
        #expect(opusUsage!.inputTokens == 2000)
        #expect(opusUsage!.outputTokens == 1000)
    }
    
    @Test func testAggregateByProject() async throws {
        let parser = JSONLParser()
        let aggregator = UsageAggregator()
        let entries = try parser.parseJSONLContent(mockJSONLContent)
        
        let projectUsage = aggregator.aggregateByProject(entries)
        
        #expect(projectUsage.count == 2)
        
        let project1Usage = projectUsage.first { $0.projectPath == "/Users/test/project1" }
        #expect(project1Usage != nil)
        #expect(project1Usage!.sessionCount == 2)
        #expect(project1Usage!.projectName == "project1")
        
        let project2Usage = projectUsage.first { $0.projectPath == "/Users/test/project2" }
        #expect(project2Usage != nil)
        #expect(project2Usage!.sessionCount == 1)
        #expect(project2Usage!.projectName == "project2")
    }
    
    @Test func testAggregateByMonth() async throws {
        let parser = JSONLParser()
        let aggregator = UsageAggregator()
        let entries = try parser.parseJSONLContent(mockJSONLContent)
        
        let monthlyUsage = aggregator.aggregateByMonth(entries)
        
        #expect(monthlyUsage.count == 2)
        
        let januaryUsage = monthlyUsage.first { $0.month == "2025-01" }
        #expect(januaryUsage != nil)
        #expect(januaryUsage!.sessionCount == 2)
        #expect(januaryUsage!.modelsUsed.contains("claude-sonnet-4"))
        #expect(januaryUsage!.modelsUsed.contains("claude-opus-4"))
        
        let februaryUsage = monthlyUsage.first { $0.month == "2025-02" }
        #expect(februaryUsage != nil)
        #expect(februaryUsage!.sessionCount == 1)
        #expect(februaryUsage!.modelsUsed.contains("claude-sonnet-4"))
        #expect(!februaryUsage!.modelsUsed.contains("claude-opus-4"))
    }
    
    @Test func testCalculateOverallStats() async throws {
        let parser = JSONLParser()
        let aggregator = UsageAggregator()
        let entries = try parser.parseJSONLContent(mockJSONLContent)
        
        let overallStats = aggregator.calculateOverallStats(entries)
        
        #expect(overallStats.totalSessions == 3)
        #expect(overallStats.totalTokens == 8100) // Sum of all tokens from all entries
        #expect(overallStats.totalCost > 0)
    }
    
    // MARK: - Integration Tests
    
    @Test func testGenerateUsageStatistics() async throws {
        let parser = JSONLParser()
        let aggregator = UsageAggregator()
        let entries = try parser.parseJSONLContent(mockJSONLContent)
        
        let stats = aggregator.generateUsageStatistics(entries)
        
        #expect(stats.totalSessions == 3)
        #expect(stats.modelUsage.count == 2)
        #expect(stats.projectUsage.count == 2)
        #expect(stats.monthlyUsage.count == 2)
        #expect(stats.dailyUsage.count == 3)
        #expect(stats.dateRange.start == "2025-01-15T10:30:00Z")
        #expect(stats.dateRange.end == "2025-02-01T09:15:00Z")
    }
    
    // MARK: - Edge Cases
    
    @Test func testEmptyUsageData() async throws {
        let emptyUsage = UsageData(
            inputTokens: nil,
            outputTokens: nil,
            cacheCreationInputTokens: nil,
            cacheReadInputTokens: nil
        )
        
        let calculator = CostCalculator()
        let cost = calculator.calculateCost(for: "claude-sonnet-4", usage: emptyUsage)
        let totalTokens = calculator.calculateTotalTokens(usage: emptyUsage)
        
        #expect(cost == 0.0)
        #expect(totalTokens == 0)
    }
    
    @Test func testEmptyJSONLContent() async throws {
        let parser = JSONLParser()
        let entries = try parser.parseJSONLContent("")
        
        #expect(entries.isEmpty)
    }
    
    @Test func testInvalidJSONLContent() async throws {
        let parser = JSONLParser()
        let invalidContent = "invalid json line"
        
        #expect(throws: JSONLParser.JSONLParserError.self) {
            try parser.parseJSONLContent(invalidContent)
        }
    }
}
