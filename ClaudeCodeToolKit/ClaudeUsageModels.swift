import Foundation

// MARK: - Raw Usage Data Models

struct UsageData: Codable {
    let inputTokens: Int?
    let outputTokens: Int?
    let cacheCreationInputTokens: Int?
    let cacheReadInputTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cacheCreationInputTokens = "cache_creation_input_tokens"
        case cacheReadInputTokens = "cache_read_input_tokens"
    }
}

struct JSONLEntry: Codable {
    let model: String
    let usage: UsageData?
    let timestamp: String
    let projectPath: String
    
    enum CodingKeys: String, CodingKey {
        case model
        case usage
        case timestamp
        case projectPath = "project_path"
    }
}

// MARK: - Aggregated Usage Models

struct ModelUsage {
    let model: String
    var totalCost: Double
    var totalTokens: Int
    var inputTokens: Int
    var outputTokens: Int
    var cacheCreationTokens: Int
    var cacheReadTokens: Int
    var sessionCount: Int
    
    init(model: String) {
        self.model = model
        self.totalCost = 0.0
        self.totalTokens = 0
        self.inputTokens = 0
        self.outputTokens = 0
        self.cacheCreationTokens = 0
        self.cacheReadTokens = 0
        self.sessionCount = 0
    }
}

struct ProjectUsage {
    let projectPath: String
    let projectName: String
    var totalCost: Double
    var totalTokens: Int
    var sessionCount: Int
    var lastUsed: String
    
    init(projectPath: String) {
        self.projectPath = projectPath
        self.projectName = (projectPath as NSString).lastPathComponent
        self.totalCost = 0.0
        self.totalTokens = 0
        self.sessionCount = 0
        self.lastUsed = ""
    }
}

struct MonthlyUsage {
    let month: String // Format: "YYYY-MM"
    var totalCost: Double
    var totalTokens: Int
    var modelsUsed: [String]
    var sessionCount: Int
    
    init(month: String) {
        self.month = month
        self.totalCost = 0.0
        self.totalTokens = 0
        self.modelsUsed = []
        self.sessionCount = 0
    }
}

struct DailyUsage {
    let date: String // Format: "YYYY-MM-DD"
    var totalCost: Double
    var totalTokens: Int
    var modelsUsed: [String]
    
    init(date: String) {
        self.date = date
        self.totalCost = 0.0
        self.totalTokens = 0
        self.modelsUsed = []
    }
}

// MARK: - Overall Usage Statistics

struct UsageStatistics {
    let totalCost: Double
    let totalTokens: Int
    let totalSessions: Int
    let modelUsage: [ModelUsage]
    let projectUsage: [ProjectUsage]
    let monthlyUsage: [MonthlyUsage]
    let dailyUsage: [DailyUsage]
    let dateRange: (start: String, end: String)
}