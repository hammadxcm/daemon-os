// Constants.swift - Consolidated magic numbers and timing values

import Foundation

/// Timing constants used across the codebase.
public enum Timing {
    public static let appFocusDelay: TimeInterval = 0.2
    public static let axNativeReactionDelay: UInt32 = 300_000
    public static let syntheticClickDelay: TimeInterval = 0.15
    public static let modifierClearDelay: UInt32 = 10_000
    public static let hotkeyProcessDelay: UInt32 = 200_000
    public static let typeCharDelay: TimeInterval = 0.01
    public static let focusRetryDelay: TimeInterval = 0.3
    public static let focusRetryLongDelay: TimeInterval = 0.5
    public static let screenshotPollInterval: TimeInterval = 0.01
    public static let screenshotDeadline: TimeInterval = 10.0
    public static let setValueDelay: UInt32 = 150_000
    public static let clearFieldDelay: TimeInterval = 0.05
    public static let focusElementDelay: TimeInterval = 0.1
    public static let readbackDelay: TimeInterval = 0.15
    public static let recipeFocusDelay: TimeInterval = 0.3
}

/// Limit constants used across the codebase.
public enum Limits {
    public static let semanticDepthBudget = 25
    public static let maxSearchDepth = 100
    public static let domIdSearchDepth = 50
    public static let waitElementSearchDepth = 15
    public static let contextInteractiveDepth = 8
    public static let scrollableSearchDepth = 5
    public static let maxSearchResults = 50
    public static let maxInteractiveElements = 30
    public static let maxFieldCandidates = 100
    public static let valueDisplayTruncation = 500
    public static let readbackTruncation = 200
    public static let maxScreenshotWidth = 1280
    public static let webAreaSearchDepth = 10
}
