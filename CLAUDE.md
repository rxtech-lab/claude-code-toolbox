# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClaudeCodeToolKit is a macOS application that analyzes Claude Code usage statistics and displays them in both a full application window and a menu bar widget. It parses Claude's JSONL usage logs to provide insights into token usage, costs, and project statistics.

## Build and Test Commands

This is an Xcode-based SwiftUI project:

- **Build**: Use Xcode to build the project (⌘+B) or `xcodebuild` from command line
- **Run**: Use Xcode to run the project (⌘+R) or build and run the .app bundle
- **Test**: Use Xcode's test navigator (⌘+U) or `xcodebuild test`

## Architecture

### Core Components

1. **ClaudeUsageCalculator**: Main calculation engine that orchestrates parsing and aggregation
2. **JSONLParser**: Parses Claude's JSONL log files from `~/.claude/usage/`
3. **UsageAggregator**: Aggregates parsed data into statistics by project, model, date, etc.
4. **CostCalculator**: Calculates costs using pricing models for different Claude variants
5. **MenuBarManager**: Manages the menu bar display and data refresh cycles

### UI Structure

- **ContentView**: Main application window with tabbed interface
- **MenuBarContentView**: Menu bar dropdown interface
- **UsageChartView**: Chart visualization of usage data
- **Various Row Views**: Reusable components for displaying statistics

### Data Flow

1. **JSONLParser** reads files from `~/.claude/usage/` directory
2. **UsageAggregator** processes entries into structured statistics
3. **CostCalculator** applies pricing models to calculate costs
4. **MenuBarManager** refreshes data every 60 seconds
5. UI components display aggregated statistics

## Key Features

- **Menu Bar Integration**: Shows real-time usage metrics (tokens, cost, monthly cost)
- **Usage Statistics**: Detailed breakdown by project, model, and time period
- **Cost Tracking**: Calculates spending based on Claude's pricing models
- **Chart Visualization**: Visual representation of usage patterns
- **Widget Support**: Includes a widget extension for quick access

## Usage Data Source

The application reads Claude Code usage logs from:
- `~/.claude/usage/` directory
- JSONL format files containing session data
- Requires appropriate file system permissions

## Development Notes

- Uses SwiftUI for the entire interface
- Implements proper error handling for file access issues
- Follows Apple's Human Interface Guidelines for menu bar apps
- Uses `@StateObject` and `@Published` for reactive data flow
- Implements proper cleanup with `deinit` for timers