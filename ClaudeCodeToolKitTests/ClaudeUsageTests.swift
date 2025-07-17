@testable import ClaudeCodeToolKit
import XCTest

final class ClaudeUsageTests: XCTestCase {
    // MARK: - Test Data
    
    private var sampleJSONLContent: String {
        """
        {"parentUuid":"590200dc-0136-4361-801a-447b1961cb9f","isSidechain":false,"userType":"external","cwd":"/Users/qiweili/Desktop/rxlab/openapi-mcp","sessionId":"692ca49d-301b-485b-b250-855ca2518b2d","version":"1.0.51","message":{"id":"msg_013SFwxKa9ytYhrVE2rUtFyG","type":"message","role":"assistant","model":"claude-sonnet-4-20250514","content":[{"type":"tool_use","id":"toolu_01F4c4KLDnmHW21X1QyzMTp5","name":"Write","input":{"file_path":"/Users/qiweili/Desktop/rxlab/openapi-mcp/tools/openlink.go","content":"package tools"}}],"stop_reason":null,"stop_sequence":null,"usage":{"input_tokens":3,"cache_creation_input_tokens":363,"cache_read_input_tokens":21100,"output_tokens":400,"service_tier":"standard"}},"requestId":"req_011CR8WoFb4tuKuP9KLFuTqc","type":"assistant","uuid":"d5f5d345-57cd-41b8-ac88-94669fd8a83f","timestamp":"2025-07-15T08:48:03.470Z"}
        {"parentUuid":"590200dc-0136-4361-801a-447b1961cb9f","isSidechain":false,"userType":"external","cwd":"/Users/qiweili/Desktop/rxlab/openapi-mcp","sessionId":"692ca49d-301b-485b-b250-855ca2518b2d","version":"1.0.51","message":{"id":"msg_014SFwxKa9ytYhrVE2rUtFyG","type":"message","role":"assistant","model":"claude-opus-4-20250514","content":[{"type":"tool_use","id":"toolu_01F4c4KLDnmHW21X1QyzMTp5","name":"Write","input":{"file_path":"/Users/qiweili/Desktop/rxlab/openapi-mcp/tools/lint.go","content":"package tools"}}],"stop_reason":null,"stop_sequence":null,"usage":{"input_tokens":5000,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":1500,"service_tier":"standard"}},"requestId":"req_011CR8WoFb4tuKuP9KLFuTqc","type":"assistant","uuid":"d5f5d345-57cd-41b8-ac88-94669fd8a83f","timestamp":"2025-07-15T09:30:03.470Z"}
        """
    }
    
    private var sampleUsageData: UsageData {
        UsageData(
            inputTokens: 3,
            outputTokens: 400,
            cacheCreationInputTokens: 363,
            cacheReadInputTokens: 21100
        )
    }
    
    private var sampleJSONLEntry: JSONLEntry {
        JSONLEntry(
            model: "claude-sonnet-4-20250514",
            usage: sampleUsageData,
            timestamp: "2025-07-15T08:48:03.470Z",
            projectPath: "/Users/qiweili/Desktop/rxlab/openapi-mcp"
        )
    }
    
    // MARK: - JSONLParser Tests
    
    func testJSONLParserParseContent() {
        let parser = JSONLParser()
        
        do {
            let entries = try parser.parseJSONLContent(sampleJSONLContent)
            
            XCTAssertEqual(entries.count, 2)
            
            let firstEntry = entries[0]
            XCTAssertEqual(firstEntry.model, "claude-sonnet-4-20250514")
            XCTAssertEqual(firstEntry.projectPath, "/Users/qiweili/Desktop/rxlab/openapi-mcp")
            XCTAssertEqual(firstEntry.timestamp, "2025-07-15T08:48:03.470Z")
            
            let firstUsage = firstEntry.usage!
            XCTAssertEqual(firstUsage.inputTokens, 3)
            XCTAssertEqual(firstUsage.outputTokens, 400)
            XCTAssertEqual(firstUsage.cacheCreationInputTokens, 363)
            XCTAssertEqual(firstUsage.cacheReadInputTokens, 21100)
            
            let secondEntry = entries[1]
            XCTAssertEqual(secondEntry.model, "claude-opus-4-20250514")
            XCTAssertEqual(secondEntry.usage?.inputTokens, 5000)
            XCTAssertEqual(secondEntry.usage?.outputTokens, 1500)
            
        } catch {
            XCTFail("Parsing should succeed: \(error)")
        }
    }
    
    func testJSONLParserEmptyContent() {
        let parser = JSONLParser()
        
        do {
            let entries = try parser.parseJSONLContent("")
            XCTAssertTrue(entries.isEmpty)
        } catch {
            XCTFail("Empty content should not throw error: \(error)")
        }
    }
    
    func testJSONLParserFilterByProject() {
        let parser = JSONLParser()
        let entries = [sampleJSONLEntry]
        
        let filtered = parser.filterEntries(entries, byProject: "/Users/qiweili/Desktop/rxlab/openapi-mcp")
        XCTAssertEqual(filtered.count, 1)
        
        let noMatch = parser.filterEntries(entries, byProject: "/some/other/path")
        XCTAssertTrue(noMatch.isEmpty)
    }
    
    func testJSONLParserFilterByModel() {
        let parser = JSONLParser()
        let entries = [sampleJSONLEntry]
        
        let filtered = parser.filterEntries(entries, byModel: "claude-sonnet-4-20250514")
        XCTAssertEqual(filtered.count, 1)
        
        let noMatch = parser.filterEntries(entries, byModel: "claude-opus-4")
        XCTAssertTrue(noMatch.isEmpty)
    }
    
    func testJSONLParserFilterByMonth() {
        let parser = JSONLParser()
        let entries = [sampleJSONLEntry]
        
        let filtered = parser.filterEntries(entries, byMonth: "2025-07")
        XCTAssertEqual(filtered.count, 1)
        
        let noMatch = parser.filterEntries(entries, byMonth: "2025-06")
        XCTAssertTrue(noMatch.isEmpty)
    }
    
    // MARK: - CostCalculator Tests
    
    func testCostCalculatorDefaultPricing() {
        let calculator = CostCalculator()
        
        // Test Sonnet 4 pricing
        let sonnetCost = calculator.calculateCost(for: "claude-sonnet-4-20250514", usage: sampleUsageData)
        let inputCost = 3 * 3.0 / 1000000.0
        let outputCost = 400 * 15.0 / 1000000.0
        let cacheWriteCost = 363 * 3.75 / 1000000.0
        let cacheReadCost = 21100 * 0.30 / 1000000.0
        let expectedSonnetCost = inputCost + outputCost + cacheWriteCost + cacheReadCost
        XCTAssertEqual(sonnetCost, expectedSonnetCost, accuracy: 0.0001)
        
        // Test Opus 4 pricing
        let opusUsage = UsageData(inputTokens: 5000, outputTokens: 1500, cacheCreationInputTokens: 0, cacheReadInputTokens: 0)
        let opusCost = calculator.calculateCost(for: "claude-opus-4-20250514", usage: opusUsage)
        let opusInputCost = 5000 * 15.0 / 1000000.0
        let opusOutputCost = 1500 * 75.0 / 1000000.0
        let expectedOpusCost = opusInputCost + opusOutputCost
        XCTAssertEqual(opusCost, expectedOpusCost, accuracy: 0.0001)
    }
    
    func testCostCalculatorCustomPricing() {
        let calculator = CostCalculator()
        
        // Test custom pricing configuration
        let customPricing = CostCalculator.CustomPricing(
            inputPrice: 1.0,
            outputPrice: 5.0,
            cacheWritePrice: 1.25,
            cacheReadPrice: 0.1
        )
        
        calculator.setCustomPricing(for: "custom-model", pricing: customPricing)
        
        let customCost = calculator.calculateCost(for: "custom-model", usage: sampleUsageData)
        let customInputCost = 3 * 1.0 / 1000000.0
        let customOutputCost = 400 * 5.0 / 1000000.0
        let customCacheWriteCost = 363 * 1.25 / 1000000.0
        let customCacheReadCost = 21100 * 0.1 / 1000000.0
        let expectedCustomCost = customInputCost + customOutputCost + customCacheWriteCost + customCacheReadCost
        XCTAssertEqual(customCost, expectedCustomCost, accuracy: 0.0001)
        
        // Test that pricing info returns custom pricing
        let pricingInfo = calculator.getPricingInfo(for: "custom-model")
        XCTAssertNotNil(pricingInfo)
        XCTAssertEqual(pricingInfo?.input, 1.0)
        XCTAssertEqual(pricingInfo?.output, 5.0)
        XCTAssertEqual(pricingInfo?.cacheWrite, 1.25)
        XCTAssertEqual(pricingInfo?.cacheRead, 0.1)
    }
  
    func testCostCalculatorTotalTokens() {
        let calculator = CostCalculator()
        
        let totalTokens = calculator.calculateTotalTokens(usage: sampleUsageData)
        XCTAssertEqual(totalTokens, 21866) // 3 + 400 + 363 + 21100
    }
    
    func testCostCalculatorSupportedModels() {
        let calculator = CostCalculator()
        
        XCTAssertTrue(calculator.isModelSupported("claude-sonnet-4-20250514"))
        XCTAssertTrue(calculator.isModelSupported("claude-opus-4-20250514"))
        XCTAssertTrue(calculator.isModelSupported("claude-haiku-3.5-20250514"))
        XCTAssertFalse(calculator.isModelSupported("unknown-model"))
    }
    
    func testCostCalculatorClaude4Pricing() {
        let calculator = CostCalculator()
        
        // Test official Claude 4 pricing function
        let claude4Function = CostCalculator.claude4Pricing()
        calculator.setPricingFunction(for: "claude-sonnet-4-test", pricingFunction: claude4Function)
        calculator.setPricingFunction(for: "claude-opus-4-test", pricingFunction: claude4Function)
        calculator.setPricingFunction(for: "claude-haiku-3.5-test", pricingFunction: claude4Function)
        
        // Test Sonnet 4 pricing
        let sonnetCost = calculator.calculateCost(for: "claude-sonnet-4-test", usage: sampleUsageData)
        let sonnetInputCost = 3 * 3.0 / 1_000_000.0
        let sonnetOutputCost = 400 * 15.0 / 1_000_000.0
        let sonnetCacheWriteCost = 363 * 3.75 / 1_000_000.0
        let sonnetCacheReadCost = 21100 * 0.30 / 1_000_000.0
        let expectedSonnetCost = sonnetInputCost + sonnetOutputCost + sonnetCacheWriteCost + sonnetCacheReadCost
        XCTAssertEqual(sonnetCost, expectedSonnetCost, accuracy: 0.0001)
        
        // Test Opus 4 pricing
        let opusUsage = UsageData(inputTokens: 1000, outputTokens: 500, cacheCreationInputTokens: 100, cacheReadInputTokens: 2000)
        let opusCost = calculator.calculateCost(for: "claude-opus-4-test", usage: opusUsage)
        let opusInputCost = 1000 * 15.0 / 1_000_000.0
        let opusOutputCost = 500 * 75.0 / 1_000_000.0
        let opusCacheWriteCost = 100 * 18.75 / 1_000_000.0
        let opusCacheReadCost = 2000 * 1.50 / 1_000_000.0
        let expectedOpusCost = opusInputCost + opusOutputCost + opusCacheWriteCost + opusCacheReadCost
        XCTAssertEqual(opusCost, expectedOpusCost, accuracy: 0.0001)
        
        // Test Haiku 3.5 pricing
        let haikuUsage = UsageData(inputTokens: 10000, outputTokens: 2000, cacheCreationInputTokens: 500, cacheReadInputTokens: 5000)
        let haikuCost = calculator.calculateCost(for: "claude-haiku-3.5-test", usage: haikuUsage)
        let haikuInputCost = 10000 * 0.80 / 1_000_000.0
        let haikuOutputCost = 2000 * 4.0 / 1_000_000.0
        let haikuCacheWriteCost = 500 * 1.0 / 1_000_000.0
        let haikuCacheReadCost = 5000 * 0.08 / 1_000_000.0
        let expectedHaikuCost = haikuInputCost + haikuOutputCost + haikuCacheWriteCost + haikuCacheReadCost
        XCTAssertEqual(haikuCost, expectedHaikuCost, accuracy: 0.0001)
        
        // Test unknown model returns 0
        let unknownCost = calculator.calculateCost(for: "unknown-model-test", usage: sampleUsageData)
        XCTAssertEqual(unknownCost, 0.0, accuracy: 0.0001)
    }
    
    func testCostCalculatorPricingInfo() {
        let calculator = CostCalculator()
        
        let sonnetPricing = calculator.getPricingInfo(for: "claude-sonnet-4-20250514")
        XCTAssertNotNil(sonnetPricing)
        XCTAssertEqual(sonnetPricing?.input, 3.0)
        XCTAssertEqual(sonnetPricing?.output, 15.0)
        XCTAssertEqual(sonnetPricing?.cacheWrite, 3.75)
        XCTAssertEqual(sonnetPricing?.cacheRead, 0.30)
        
        let unknownPricing = calculator.getPricingInfo(for: "unknown-model")
        XCTAssertNil(unknownPricing)
    }
    
    // MARK: - UsageAggregator Tests
    
    func testUsageAggregatorByModel() {
        let aggregator = UsageAggregator()
        let entries = [sampleJSONLEntry]
        
        let modelUsage = aggregator.aggregateByModel(entries)
        
        XCTAssertEqual(modelUsage.count, 1)
        let usage = modelUsage[0]
        XCTAssertEqual(usage.model, "claude-sonnet-4-20250514")
        XCTAssertEqual(usage.inputTokens, 3)
        XCTAssertEqual(usage.outputTokens, 400)
        XCTAssertEqual(usage.cacheCreationTokens, 363)
        XCTAssertEqual(usage.cacheReadTokens, 21100)
        XCTAssertEqual(usage.sessionCount, 1)
        XCTAssertGreaterThan(usage.totalCost, 0)
    }
    
    func testUsageAggregatorByProject() {
        let aggregator = UsageAggregator()
        let entries = [sampleJSONLEntry]
        
        let projectUsage = aggregator.aggregateByProject(entries)
        
        XCTAssertEqual(projectUsage.count, 1)
        let usage = projectUsage[0]
        XCTAssertEqual(usage.projectPath, "/Users/qiweili/Desktop/rxlab/openapi-mcp")
        XCTAssertEqual(usage.projectName, "openapi-mcp")
        XCTAssertEqual(usage.sessionCount, 1)
        XCTAssertGreaterThan(usage.totalCost, 0)
        XCTAssertGreaterThan(usage.totalTokens, 0)
    }
    
    func testUsageAggregatorByMonth() {
        let aggregator = UsageAggregator()
        let entries = [sampleJSONLEntry]
        
        let monthlyUsage = aggregator.aggregateByMonth(entries)
        
        XCTAssertEqual(monthlyUsage.count, 1)
        let usage = monthlyUsage[0]
        XCTAssertEqual(usage.month, "2025-07")
        XCTAssertEqual(usage.sessionCount, 1)
        XCTAssertEqual(usage.modelsUsed, ["claude-sonnet-4-20250514"])
        XCTAssertGreaterThan(usage.totalCost, 0)
    }
    
    func testUsageAggregatorByDay() {
        let aggregator = UsageAggregator()
        let entries = [sampleJSONLEntry]
        
        let dailyUsage = aggregator.aggregateByDay(entries)
        
        XCTAssertEqual(dailyUsage.count, 1)
        let usage = dailyUsage[0]
        XCTAssertEqual(usage.date, "2025-07-15")
        XCTAssertEqual(usage.modelsUsed, ["claude-sonnet-4-20250514"])
        XCTAssertGreaterThan(usage.totalCost, 0)
    }
    
    func testUsageAggregatorOverallStats() {
        let aggregator = UsageAggregator()
        let entries = [sampleJSONLEntry]
        
        let stats = aggregator.calculateOverallStats(entries)
        
        XCTAssertGreaterThan(stats.totalCost, 0)
        XCTAssertEqual(stats.totalTokens, 21866)
        XCTAssertEqual(stats.totalSessions, 1)
    }
    
    func testUsageAggregatorGenerateStatistics() {
        let aggregator = UsageAggregator()
        let entries = [sampleJSONLEntry]
        
        let statistics = aggregator.generateUsageStatistics(entries)
        
        XCTAssertGreaterThan(statistics.totalCost, 0)
        XCTAssertEqual(statistics.totalTokens, 21866)
        XCTAssertEqual(statistics.totalSessions, 1)
        XCTAssertEqual(statistics.modelUsage.count, 1)
        XCTAssertEqual(statistics.projectUsage.count, 1)
        XCTAssertEqual(statistics.monthlyUsage.count, 1)
        XCTAssertEqual(statistics.dailyUsage.count, 1)
        XCTAssertEqual(statistics.dateRange.start, "2025-07-15T08:48:03.470Z")
        XCTAssertEqual(statistics.dateRange.end, "2025-07-15T08:48:03.470Z")
    }
    
    // MARK: - ClaudeUsageCalculator Tests
    
    func testClaudeUsageCalculatorMethods() {
        let calculator = ClaudeUsageCalculator()
        
        XCTAssertTrue(calculator.getSupportedModels().count > 0)
        XCTAssertTrue(calculator.isModelSupported("claude-sonnet-4-20250514"))
        XCTAssertNotNil(calculator.getPricingInfo(for: "claude-sonnet-4-20250514"))
    }
    
    func testClaudeUsageCalculatorDiscovery() {
        let calculator = ClaudeUsageCalculator()
        
        // These methods should not throw errors even if no data is available
        let projects = calculator.discoverAvailableProjects()
        let models = calculator.discoverAvailableModels()
        let months = calculator.discoverAvailableMonths()
        
        XCTAssertTrue(projects.count >= 0)
        XCTAssertTrue(models.count >= 0)
        XCTAssertTrue(months.count >= 0)
    }
    
    // MARK: - Integration Tests
    
    func testFullWorkflow() {
        let parser = JSONLParser()
        let aggregator = UsageAggregator()
        
        do {
            let entries = try parser.parseJSONLContent(sampleJSONLContent)
            let statistics = aggregator.generateUsageStatistics(entries)
            
            XCTAssertEqual(statistics.totalSessions, 2)
            XCTAssertEqual(statistics.modelUsage.count, 2)
            XCTAssertEqual(statistics.projectUsage.count, 1)
            XCTAssertGreaterThan(statistics.totalCost, 0)
            XCTAssertGreaterThan(statistics.totalTokens, 0)
            
        } catch {
            XCTFail("Full workflow should succeed: \(error)")
        }
    }
    
    func testMultipleModelsAndProjects() {
        let parser = JSONLParser()
        let aggregator = UsageAggregator()
        
        let multipleEntriesContent = """
        {"timestamp":"2025-07-15T08:48:03.470Z","cwd":"/project1","message":{"model":"claude-sonnet-4-20250514","usage":{"input_tokens":100,"output_tokens":200,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}}
        {"timestamp":"2025-07-15T09:48:03.470Z","cwd":"/project2","message":{"model":"claude-opus-4-20250514","usage":{"input_tokens":300,"output_tokens":400,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}}
        """
        
        do {
            let entries = try parser.parseJSONLContent(multipleEntriesContent)
            let statistics = aggregator.generateUsageStatistics(entries)
            
            XCTAssertEqual(statistics.totalSessions, 2)
            XCTAssertEqual(statistics.modelUsage.count, 2)
            XCTAssertEqual(statistics.projectUsage.count, 2)
            
            // Verify models are correctly identified
            let models = statistics.modelUsage.map { $0.model }.sorted()
            XCTAssertEqual(models, ["claude-opus-4-20250514", "claude-sonnet-4-20250514"])
            
            // Verify projects are correctly identified
            let projects = statistics.projectUsage.map { $0.projectPath }.sorted()
            XCTAssertEqual(projects, ["/project1", "/project2"])
            
        } catch {
            XCTFail("Multiple entries parsing should succeed: \(error)")
        }
    }
}
