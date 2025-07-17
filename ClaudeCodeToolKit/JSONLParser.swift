import Foundation

class JSONLParser {
    
    // MARK: - Error Types
    
    enum JSONLParserError: Error {
        case fileNotFound
        case invalidData
        case parsingError(String)
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
                
                let entry = try JSONDecoder().decode(JSONLEntry.self, from: data)
                entries.append(entry)
            } catch {
                throw JSONLParserError.parsingError("Error parsing line \(index + 1): \(error.localizedDescription)")
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