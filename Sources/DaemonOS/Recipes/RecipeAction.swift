// RecipeAction.swift - Type-safe recipe action enum

import Foundation

/// All valid recipe step actions.
public enum RecipeAction: String, Codable, Sendable, CaseIterable {
    case click
    case type
    case press
    case hotkey
    case focus
    case scroll
    case wait
}
