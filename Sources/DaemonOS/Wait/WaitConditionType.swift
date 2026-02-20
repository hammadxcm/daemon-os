// WaitConditionType.swift - Type-safe wait condition enum

import Foundation

/// All valid wait conditions.
public enum WaitConditionType: String, Codable, Sendable, CaseIterable {
    case urlContains
    case titleContains
    case elementExists
    case elementGone
    case urlChanged
    case titleChanged
    case delay
}
