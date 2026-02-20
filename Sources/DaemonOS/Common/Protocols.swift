// Protocols.swift - Testability protocols for dependency injection

import Foundation

/// Protocol for focus management operations.
public protocol FocusManageable: Sendable {
    @MainActor static func focus(appName: String, windowTitle: String?) -> ToolResult
    @MainActor static func saveFrontmostApp() -> Any?
    @MainActor static func clearModifierFlags()
}

/// Protocol for recipe storage operations.
public protocol RecipeStorable: Sendable {
    @MainActor static func listRecipes() -> [Recipe]
    @MainActor static func loadRecipe(named name: String) -> Recipe?
    @MainActor static func saveRecipe(_ recipe: Recipe) throws
    @MainActor static func deleteRecipe(named name: String) -> Bool
    @MainActor static func saveRecipeJSON(_ jsonString: String) throws -> String
}
