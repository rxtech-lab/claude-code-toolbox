import Foundation

class JSONLParser {
    // MARK: - Error Types
    
    enum JSONLParserError: Error {
        case fileNotFound
        case invalidData
        case parsingError(String)
    }
    
    // MARK: - Raw Message Types
    
    struct RawJSONLMessage: Codable {
        let type: String?
        let sessionId: String?
        let timestamp: String?
        let cwd: String?
        let model: String?
        let message: MessageContent?
    }
    
    struct MessageContent: Codable {
        let role: String?
        let model: String?
        let usage: UsageData?
    }
    
    // MARK: - Public Methods
    
    func parseJSONLFile(at path: String) throws -> [JSONLEntry] {
        guard let data = FileManager.default.contents(atPath: path) else {
            throw JSONLParserError.fileNotFound
        }
        
        let content = String(data: data, encoding: .utf8) ?? ""
        return try parseJSONLContent(content)
    }
    
    func parseJSONLContent(_ content: String) throws -> [JSONLEntry] {
        var entries: [JSONLEntry] = []
        let lines = content.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines
            if trimmedLine.isEmpty {
                continue
            }
            
            do {
                guard let data = trimmedLine.data(using: .utf8) else {
                    throw JSONLParserError.invalidData
                }
                
                // Parse the raw message first
                let rawMessage = try JSONDecoder().decode(RawJSONLMessage.self, from: data)
                
                // Only process messages that have usage data and required fields
                if let usage = rawMessage.message?.usage,
                   let timestamp = rawMessage.timestamp,
                   let cwd = rawMessage.cwd
                {
                    // Check for model in top level or nested in message
                    let model = rawMessage.model ?? rawMessage.message?.model
                    
                    if let model = model {
                        let entry = JSONLEntry(
                            model: model,
                            usage: usage,
                            timestamp: timestamp,
                            projectPath: cwd
                        )
                        entries.append(entry)
                    }
                }
                
            } catch {
                // Continue parsing other lines even if one fails
                print("Error parsing line \(index + 1): \(error)")
                continue
            }
        }
        
        return entries
    }
    
    // MARK: - File Discovery
    
    func discoverJSONLFiles() -> [String] {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let claudeDirectory = homeDirectory.appendingPathComponent(".claude/projects")
        
        return findJSONLFiles(in: claudeDirectory.path)
    }
    
    private func findJSONLFiles(in directory: String) -> [String] {
        var jsonlFiles: [String] = []
        
        guard let enumerator = FileManager.default.enumerator(atPath: directory) else {
            return jsonlFiles
        }
        
        for case let file as String in enumerator {
            if file.hasSuffix(".jsonl") {
                let fullPath = (directory as NSString).appendingPathComponent(file)
                jsonlFiles.append(fullPath)
            }
        }
        
        return jsonlFiles
    }
    
    // MARK: - Batch Processing
    
    func parseAllJSONLFiles() throws -> [JSONLEntry] {
        let files = discoverJSONLFiles()
        var allEntries: [JSONLEntry] = []
        
        for file in files {
            do {
                let entries = try parseJSONLFile(at: file)
                allEntries.append(contentsOf: entries)
            } catch {
                print("Warning: Failed to parse file \(file): \(error.localizedDescription)")
                continue
            }
        }
        
        return allEntries
    }
    
    // MARK: - Filtering
    
    func filterEntries(_ entries: [JSONLEntry], byProject projectPath: String) -> [JSONLEntry] {
        return entries.filter { $0.projectPath == projectPath }
    }
    
    func filterEntries(_ entries: [JSONLEntry], byModel model: String) -> [JSONLEntry] {
        return entries.filter { $0.model == model }
    }
    
    func filterEntries(_ entries: [JSONLEntry], byDateRange start: Date, end: Date) -> [JSONLEntry] {
        let dateFormatter = ISO8601DateFormatter()
        
        return entries.filter { entry in
            guard let date = dateFormatter.date(from: entry.timestamp) else {
                return false
            }
            return date >= start && date <= end
        }
    }
    
    func filterEntries(_ entries: [JSONLEntry], byMonth month: String) -> [JSONLEntry] {
        return entries.filter { entry in
            let datePrefix = String(entry.timestamp.prefix(7)) // "YYYY-MM"
            return datePrefix == month
        }
    }
}
