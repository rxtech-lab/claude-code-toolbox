//
//  extensions.swift
//  ClaudeCodeToolKit
//
//  Created by Qiwei Li on 7/17/25.
//

extension Int {
    func formattedTokens() -> String {
        if self >= 1_000_000 {
            let millions = Double(self) / 1_000_000.0
            return String(format: "%.1fM", millions)
        } else if self >= 1_000 {
            let thousands = Double(self) / 1_000.0
            return String(format: "%.1fK", thousands)
        } else {
            return formatted()
        }
    }
}
