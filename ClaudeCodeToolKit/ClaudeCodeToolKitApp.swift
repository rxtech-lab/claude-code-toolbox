//
//  ClaudeCodeToolKitApp.swift
//  ClaudeCodeToolKit
//
//  Created by Qiwei Li on 7/17/25.
//

import SwiftUI

@main
struct ClaudeCodeToolKitApp: App {
    @StateObject private var menuBarManager = MenuBarManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About ClaudeCodeToolKit") {
                    NSApplication.shared.orderFrontStandardAboutPanel()
                }
            }
        }

        MenuBarExtra {
            MenuBarContentView(menuBarManager: menuBarManager)
        } label: {
            HStack(spacing: 2) {
                Image(systemName: iconForDisplayType(menuBarManager.displayType))
                    .foregroundColor(.primary)
                Text(menuBarManager.currentDisplayValue.isEmpty ? "Loading..." : menuBarManager.currentDisplayValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
    }

    private func iconForDisplayType(_ type: MenuBarDisplayType) -> String {
        switch type {
        case .totalTokens:
            return "number.circle.fill"
        case .totalCoast:
            return "dollarsign.circle.fill"
        case .monthlyCoast:
            return "calendar.badge.clock"
        }
    }
}
