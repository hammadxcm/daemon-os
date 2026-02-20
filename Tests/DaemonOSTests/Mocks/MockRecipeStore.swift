// MockRecipeStore.swift - In-memory recipe storage for testing

import Foundation
@testable import DaemonOS

/// In-memory recipe store for unit testing recipe operations.
final class MockRecipeStore {
    var recipes: [String: Recipe] = [:]

    func listRecipes() -> [Recipe] {
        Array(recipes.values).sorted { $0.name < $1.name }
    }

    func loadRecipe(named name: String) -> Recipe? {
        recipes[name]
    }

    func saveRecipe(_ recipe: Recipe) {
        recipes[recipe.name] = recipe
    }

    func deleteRecipe(named name: String) -> Bool {
        recipes.removeValue(forKey: name) != nil
    }

    func reset() {
        recipes.removeAll()
    }
}
