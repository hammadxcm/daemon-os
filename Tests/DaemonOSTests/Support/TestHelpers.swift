// TestHelpers.swift - Shared test utilities and fixture data

import Foundation
@testable import DaemonOS

/// Helpers for building test data.
enum TestFixtures {

    /// Build a minimal valid Recipe JSON string.
    static func minimalRecipeJSON(name: String = "test-recipe") -> String {
        """
        {
            "schema_version": 2,
            "name": "\(name)",
            "description": "A test recipe",
            "steps": [
                {
                    "id": 1,
                    "action": "click",
                    "params": {"query": "OK"}
                }
            ]
        }
        """
    }

    /// Build a Recipe with custom params.
    static func recipe(
        name: String = "test",
        description: String = "Test recipe",
        app: String? = nil,
        params: [String: RecipeParam]? = nil,
        preconditions: RecipePreconditions? = nil,
        steps: [RecipeStep] = [],
        onFailure: String? = nil
    ) -> Recipe {
        let json: [String: Any] = {
            var dict: [String: Any] = [
                "schema_version": 2,
                "name": name,
                "description": description,
                "steps": steps.isEmpty ? [["id": 1, "action": "click"]] : [],
            ]
            if let app { dict["app"] = app }
            if let onFailure { dict["on_failure"] = onFailure }
            return dict
        }()

        let data = try! JSONSerialization.data(withJSONObject: json)
        return try! JSONDecoder().decode(Recipe.self, from: data)
    }

    /// Build a ToolResult args dictionary for testing.
    static func args(_ pairs: (String, Any)...) -> [String: Any] {
        var dict: [String: Any] = [:]
        for (key, value) in pairs {
            dict[key] = value
        }
        return dict
    }
}
