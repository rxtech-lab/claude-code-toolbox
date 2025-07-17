import Foundation

class CostCalculator {
    
    // MARK: - Pricing Constants (per million tokens)
    
    private struct PricingConstants {
        // Opus 4 Pricing
        static let opus4InputPrice: Double = 15.00
        static let opus4OutputPrice: Double = 75.00
        static let opus4CacheWritePrice: Double = 18.75
        static let opus4CacheReadPrice: Double = 1.50
        
        // Sonnet 4 Pricing
        static let sonnet4InputPrice: Double = 3.00
        static let sonnet4OutputPrice: Double = 15.00
        static let sonnet4CacheWritePrice: Double = 3.75
        static let sonnet4CacheReadPrice: Double = 0.30
    }
    
    // MARK: - Cost Calculation
    
    func calculateCost(for model: String, usage: UsageData) -> Double {
        let inputTokens = Double(usage.inputTokens ?? 0)
        let outputTokens = Double(usage.outputTokens ?? 0)
        let cacheCreationTokens = Double(usage.cacheCreationInputTokens ?? 0)
        let cacheReadTokens = Double(usage.cacheReadInputTokens ?? 0)
        
        let (inputPrice, outputPrice, cacheWritePrice, cacheReadPrice) = getPricing(for: model)
        
        // Calculate cost (prices are per million tokens)
        let cost = (inputTokens * inputPrice / 1_000_000.0) +
                   (outputTokens * outputPrice / 1_000_000.0) +
                   (cacheCreationTokens * cacheWritePrice / 1_000_000.0) +
                   (cacheReadTokens * cacheReadPrice / 1_000_000.0)
        
        return cost
    }
    
    private func getPricing(for model: String) -> (input: Double, output: Double, cacheWrite: Double, cacheRead: Double) {
        let lowercaseModel = model.lowercased()
        
        if lowercaseModel.contains("opus-4") || lowercaseModel.contains("claude-opus-4") {
            return (
                PricingConstants.opus4InputPrice,
                PricingConstants.opus4OutputPrice,
                PricingConstants.opus4CacheWritePrice,
                PricingConstants.opus4CacheReadPrice
            )
        } else if lowercaseModel.contains("sonnet-4") || lowercaseModel.contains("claude-sonnet-4") {
            return (
                PricingConstants.sonnet4InputPrice,
                PricingConstants.sonnet4OutputPrice,
                PricingConstants.sonnet4CacheWritePrice,
                PricingConstants.sonnet4CacheReadPrice
            )
        } else {
            // Return 0 for unknown models to avoid incorrect cost estimations
            return (0.0, 0.0, 0.0, 0.0)
        }
    }
    
    // MARK: - Token Calculations
    
    func calculateTotalTokens(usage: UsageData) -> Int {
        let inputTokens = usage.inputTokens ?? 0
        let outputTokens = usage.outputTokens ?? 0
        let cacheCreationTokens = usage.cacheCreationInputTokens ?? 0
        let cacheReadTokens = usage.cacheReadInputTokens ?? 0
        
        return inputTokens + outputTokens + cacheCreationTokens + cacheReadTokens
    }
    
    // MARK: - Supported Models
    
    func getSupportedModels() -> [String] {
        return ["opus-4", "claude-opus-4", "sonnet-4", "claude-sonnet-4"]
    }
    
    func isModelSupported(_ model: String) -> Bool {
        let lowercaseModel = model.lowercased()
        return getSupportedModels().contains { lowercaseModel.contains($0) }
    }
    
    // MARK: - Pricing Information
    
    func getPricingInfo(for model: String) -> (input: Double, output: Double, cacheWrite: Double, cacheRead: Double)? {
        guard isModelSupported(model) else { return nil }
        return getPricing(for: model)
    }
}