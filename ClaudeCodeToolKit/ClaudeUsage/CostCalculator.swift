import Foundation

class CostCalculator {
    // MARK: - Pricing Function Type
    
    /// Pricing function that takes usage data and model name and returns price in USD
    typealias PricingFunction = (_ usage: UsageData, _ modelName: String) -> Double
    
    // MARK: - Custom Pricing Structure (Legacy Support)
    
    struct CustomPricing {
        let inputPrice: Double
        let outputPrice: Double
        let cacheWritePrice: Double
        let cacheReadPrice: Double
    }
    
    // MARK: - Pricing Storage
    
    private var customPricingMap: [String: CustomPricing] = [:]
    private var pricingFunctionMap: [String: PricingFunction] = [:]
    
    // MARK: - Pricing Constants (per million tokens)
    // Official Anthropic API pricing as of 2025
    
    private enum PricingConstants {
        // Claude Opus 4 Pricing
        static let opus4InputPrice: Double = 15.00
        static let opus4OutputPrice: Double = 75.00
        static let opus4CacheWritePrice: Double = 18.75
        static let opus4CacheReadPrice: Double = 1.50
        
        // Claude Sonnet 4 Pricing
        static let sonnet4InputPrice: Double = 3.00
        static let sonnet4OutputPrice: Double = 15.00
        static let sonnet4CacheWritePrice: Double = 3.75
        static let sonnet4CacheReadPrice: Double = 0.30
        
        // Claude Haiku 3.5 Pricing
        static let haiku35InputPrice: Double = 0.80
        static let haiku35OutputPrice: Double = 4.00
        static let haiku35CacheWritePrice: Double = 1.00
        static let haiku35CacheReadPrice: Double = 0.08
    }
    
    // MARK: - Function-Based Pricing Management
    
    /// Set a custom pricing function for a specific model
    public func setPricingFunction(for model: String, pricingFunction: @escaping PricingFunction) {
        pricingFunctionMap[model] = pricingFunction
    }
    
    /// Get the pricing function for a specific model
    func getPricingFunction(for model: String) -> PricingFunction? {
        return pricingFunctionMap[model]
    }
    
    /// Remove custom pricing function for a specific model
    func removePricingFunction(for model: String) {
        pricingFunctionMap.removeValue(forKey: model)
    }
    
    /// Clear all custom pricing functions
    func clearAllPricingFunctions() {
        pricingFunctionMap.removeAll()
    }
    
    // MARK: - Legacy Custom Pricing Management
    
    func setCustomPricing(for model: String, pricing: CustomPricing) {
        customPricingMap[model] = pricing
    }
    
    func getCustomPricing(for model: String) -> CustomPricing? {
        return customPricingMap[model]
    }
    
    func removeCustomPricing(for model: String) {
        customPricingMap.removeValue(forKey: model)
    }
    
    func clearAllCustomPricing() {
        customPricingMap.removeAll()
    }
    
    // MARK: - Cost Calculation
    
    func calculateCost(for model: String, usage: UsageData) -> Double {
        // Priority 1: Check for custom pricing function
        if let pricingFunction = getPricingFunction(for: model) {
            return pricingFunction(usage, model)
        }
        
        // Priority 2: Check for legacy custom pricing
        if let customPricing = getCustomPricing(for: model) {
            return calculateCostWithCustomPricing(for: model, usage: usage, customPricing: customPricing)
        }
        
        // Priority 3: Use default pricing
        return calculateCostWithDefaultPricing(for: model, usage: usage)
    }
    
    private func calculateCostWithCustomPricing(for model: String, usage: UsageData, customPricing: CustomPricing) -> Double {
        let inputTokens = Double(usage.inputTokens ?? 0)
        let outputTokens = Double(usage.outputTokens ?? 0)
        let cacheCreationTokens = Double(usage.cacheCreationInputTokens ?? 0)
        let cacheReadTokens = Double(usage.cacheReadInputTokens ?? 0)
        
        // Calculate cost (prices are per million tokens)
        let cost = (inputTokens * customPricing.inputPrice / 1_000_000.0) +
            (outputTokens * customPricing.outputPrice / 1_000_000.0) +
            (cacheCreationTokens * customPricing.cacheWritePrice / 1_000_000.0) +
            (cacheReadTokens * customPricing.cacheReadPrice / 1_000_000.0)
        
        return cost
    }
    
    private func calculateCostWithDefaultPricing(for model: String, usage: UsageData) -> Double {
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
        } else if lowercaseModel.contains("haiku-3.5") || lowercaseModel.contains("claude-haiku-3.5") {
            return (
                PricingConstants.haiku35InputPrice,
                PricingConstants.haiku35OutputPrice,
                PricingConstants.haiku35CacheWritePrice,
                PricingConstants.haiku35CacheReadPrice
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
        return ["opus-4", "claude-opus-4", "sonnet-4", "claude-sonnet-4", "haiku-3.5", "claude-haiku-3.5"]
    }
    
    func isModelSupported(_ model: String) -> Bool {
        let lowercaseModel = model.lowercased()
        return getSupportedModels().contains { lowercaseModel.contains($0) }
    }
    
    // MARK: - Pricing Information
    
    func getPricingInfo(for model: String) -> (input: Double, output: Double, cacheWrite: Double, cacheRead: Double)? {
        // Check for custom pricing first
        if let customPricing = getCustomPricing(for: model) {
            return (customPricing.inputPrice, customPricing.outputPrice, customPricing.cacheWritePrice, customPricing.cacheReadPrice)
        }
        
        guard isModelSupported(model) else { return nil }
        return getPricing(for: model)
    }
    
    func getAllCustomPricing() -> [String: CustomPricing] {
        return customPricingMap
    }
    
    func getAllPricingFunctions() -> [String: PricingFunction] {
        return pricingFunctionMap
    }
    
    func hasPricingFunction(for model: String) -> Bool {
        return pricingFunctionMap[model] != nil
    }
    
    func hasCustomPricing(for model: String) -> Bool {
        return customPricingMap[model] != nil
    }
    
    // MARK: - Official Claude 4 Pricing Function
    
    /// Returns the official Claude 4 pricing function using current Anthropic API pricing
    static func claude4Pricing() -> PricingFunction {
        return { usage, modelName in
            let inputTokens = Double(usage.inputTokens ?? 0)
            let outputTokens = Double(usage.outputTokens ?? 0)
            let cacheCreationTokens = Double(usage.cacheCreationInputTokens ?? 0)
            let cacheReadTokens = Double(usage.cacheReadInputTokens ?? 0)
            
            let lowercaseModel = modelName.lowercased()
            
            // Claude Opus 4
            if lowercaseModel.contains("opus-4") || lowercaseModel.contains("claude-opus-4") {
                return (inputTokens * PricingConstants.opus4InputPrice / 1_000_000.0) +
                       (outputTokens * PricingConstants.opus4OutputPrice / 1_000_000.0) +
                       (cacheCreationTokens * PricingConstants.opus4CacheWritePrice / 1_000_000.0) +
                       (cacheReadTokens * PricingConstants.opus4CacheReadPrice / 1_000_000.0)
            }
            // Claude Sonnet 4
            else if lowercaseModel.contains("sonnet-4") || lowercaseModel.contains("claude-sonnet-4") {
                return (inputTokens * PricingConstants.sonnet4InputPrice / 1_000_000.0) +
                       (outputTokens * PricingConstants.sonnet4OutputPrice / 1_000_000.0) +
                       (cacheCreationTokens * PricingConstants.sonnet4CacheWritePrice / 1_000_000.0) +
                       (cacheReadTokens * PricingConstants.sonnet4CacheReadPrice / 1_000_000.0)
            }
            // Claude Haiku 3.5
            else if lowercaseModel.contains("haiku-3.5") || lowercaseModel.contains("claude-haiku-3.5") {
                return (inputTokens * PricingConstants.haiku35InputPrice / 1_000_000.0) +
                       (outputTokens * PricingConstants.haiku35OutputPrice / 1_000_000.0) +
                       (cacheCreationTokens * PricingConstants.haiku35CacheWritePrice / 1_000_000.0) +
                       (cacheReadTokens * PricingConstants.haiku35CacheReadPrice / 1_000_000.0)
            }
            // Unknown model
            else {
                return 0.0
            }
        }
    }
    
    // MARK: - Convenience Pricing Functions
    
    /// Creates a model-specific pricing function that can handle different models differently
    static func modelSpecificPricing(pricingRules: [String: (input: Double, output: Double, cacheWrite: Double, cacheRead: Double)], defaultPrice: Double = 0.0) -> PricingFunction {
        return { usage, modelName in
            let inputTokens = Double(usage.inputTokens ?? 0)
            let outputTokens = Double(usage.outputTokens ?? 0)
            let cacheCreationTokens = Double(usage.cacheCreationInputTokens ?? 0)
            let cacheReadTokens = Double(usage.cacheReadInputTokens ?? 0)
            
            // Find matching pricing rule
            for (modelPattern, pricing) in pricingRules {
                if modelName.lowercased().contains(modelPattern.lowercased()) {
                    return (inputTokens * pricing.input / 1_000_000.0) +
                        (outputTokens * pricing.output / 1_000_000.0) +
                        (cacheCreationTokens * pricing.cacheWrite / 1_000_000.0) +
                        (cacheReadTokens * pricing.cacheRead / 1_000_000.0)
                }
            }
            
            // Fallback to default price if no pattern matches
            let totalTokens = inputTokens + outputTokens + cacheCreationTokens + cacheReadTokens
            return totalTokens * defaultPrice / 1_000_000.0
        }
    }
}
