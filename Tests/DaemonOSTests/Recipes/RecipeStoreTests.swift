// RecipeStoreTests.swift - Unit tests for RecipeStore file-based storage

import Foundation
import Testing
@testable import DaemonOS

@Suite("RecipeStore")
struct RecipeStoreTests {

    @Test("saveRecipeJSON with valid JSON succeeds")
    func saveValidJSON() throws {
        let json = """
        {
            "schema_version": 2,
            "name": "test-recipe-\(UUID().uuidString.prefix(8))",
            "description": "Test recipe",
            "steps": [{"id": 1, "action": "click", "params": {"query": "OK"}}]
        }
        """
        let name = try RecipeStore.saveRecipeJSON(json)
        #expect(name.hasPrefix("test-recipe-"))
        // Cleanup
        _ = RecipeStore.deleteRecipe(named: name)
    }

    @Test("saveRecipeJSON with invalid JSON throws")
    func saveInvalidJSON() {
        #expect(throws: (any Error).self) {
            try RecipeStore.saveRecipeJSON("not json at all{{{")
        }
    }

    @Test("saveRecipeJSON with missing required fields throws")
    func saveMissingFields() {
        let json = """
        {"name": "test", "description": "missing steps and schema"}
        """
        #expect(throws: (any Error).self) {
            try RecipeStore.saveRecipeJSON(json)
        }
    }

    @Test("loadRecipe returns nil for nonexistent recipe")
    func loadNonexistent() {
        let result = RecipeStore.loadRecipe(named: "nonexistent-recipe-xyz-12345")
        #expect(result == nil)
    }

    @Test("deleteRecipe returns false for nonexistent recipe")
    func deleteNonexistent() {
        let result = RecipeStore.deleteRecipe(named: "nonexistent-recipe-xyz-12345")
        #expect(result == false)
    }

    @Test("save and load round-trip")
    func saveAndLoadRoundTrip() throws {
        let uniqueName = "test-roundtrip-\(UUID().uuidString.prefix(8))"
        let json = """
        {
            "schema_version": 2,
            "name": "\(uniqueName)",
            "description": "Round trip test",
            "steps": [{"id": 1, "action": "click", "params": {"query": "OK"}}]
        }
        """
        let name = try RecipeStore.saveRecipeJSON(json)
        #expect(name == uniqueName)

        let loaded = RecipeStore.loadRecipe(named: name)
        #expect(loaded != nil)
        #expect(loaded?.name == uniqueName)
        #expect(loaded?.description == "Round trip test")
        #expect(loaded?.steps.count == 1)

        // Cleanup
        let deleted = RecipeStore.deleteRecipe(named: name)
        #expect(deleted == true)
    }

    @Test("listRecipes returns sorted results")
    func listRecipesSorted() throws {
        let name1 = "zzz-test-\(UUID().uuidString.prefix(8))"
        let name2 = "aaa-test-\(UUID().uuidString.prefix(8))"

        let json1 = """
        {"schema_version": 2, "name": "\(name1)", "description": "Z recipe", "steps": [{"id": 1, "action": "click"}]}
        """
        let json2 = """
        {"schema_version": 2, "name": "\(name2)", "description": "A recipe", "steps": [{"id": 1, "action": "click"}]}
        """

        _ = try RecipeStore.saveRecipeJSON(json1)
        _ = try RecipeStore.saveRecipeJSON(json2)

        let all = RecipeStore.listRecipes()
        let ourRecipes = all.filter { $0.name == name1 || $0.name == name2 }
        #expect(ourRecipes.count == 2)

        // Should be sorted alphabetically
        if ourRecipes.count == 2 {
            #expect(ourRecipes[0].name == name2) // aaa before zzz
            #expect(ourRecipes[1].name == name1)
        }

        // Cleanup
        _ = RecipeStore.deleteRecipe(named: name1)
        _ = RecipeStore.deleteRecipe(named: name2)
    }
}
