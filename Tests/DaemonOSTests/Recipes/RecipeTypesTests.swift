// RecipeTypesTests.swift - Unit tests for Recipe data structures

import AXorcist
import Foundation
import Testing
@testable import DaemonOS

@Suite("RecipeTypes Tests")
struct RecipeTypesTests {

    // MARK: - RecipeParam

    @Test("RecipeParam Codable round-trip")
    func recipeParamCodable() throws {
        let param = RecipeParam(type: "string", description: "The channel name", required: true)
        let data = try JSONEncoder().encode(param)
        let decoded = try JSONDecoder().decode(RecipeParam.self, from: data)
        #expect(decoded.type == "string")
        #expect(decoded.description == "The channel name")
        #expect(decoded.required == true)
    }

    @Test("RecipeParam with optional required nil")
    func recipeParamOptionalRequired() throws {
        let param = RecipeParam(type: "number", description: "A count", required: nil)
        let data = try JSONEncoder().encode(param)
        let decoded = try JSONDecoder().decode(RecipeParam.self, from: data)
        #expect(decoded.type == "number")
        #expect(decoded.required == nil)
    }

    // MARK: - RecipePreconditions

    @Test("RecipePreconditions Codable round-trip")
    func recipePreconditionsCodable() throws {
        let preconditions = RecipePreconditions(appRunning: "Safari", urlContains: "github.com")
        let data = try JSONEncoder().encode(preconditions)
        let decoded = try JSONDecoder().decode(RecipePreconditions.self, from: data)
        #expect(decoded.appRunning == "Safari")
        #expect(decoded.urlContains == "github.com")
    }

    @Test("RecipePreconditions snake_case CodingKeys decode correctly")
    func recipePreconditionsSnakeCaseKeys() throws {
        let json = """
        {"app_running": "Slack", "url_contains": "slack.com"}
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(RecipePreconditions.self, from: data)
        #expect(decoded.appRunning == "Slack")
        #expect(decoded.urlContains == "slack.com")
    }

    @Test("RecipePreconditions with nil fields")
    func recipePreconditionsNilFields() throws {
        let preconditions = RecipePreconditions(appRunning: nil, urlContains: nil)
        let data = try JSONEncoder().encode(preconditions)
        let decoded = try JSONDecoder().decode(RecipePreconditions.self, from: data)
        #expect(decoded.appRunning == nil)
        #expect(decoded.urlContains == nil)
    }

    // MARK: - RecipeWaitCondition

    @Test("RecipeWaitCondition Codable round-trip")
    func recipeWaitConditionCodable() throws {
        let condition = RecipeWaitCondition(
            condition: "elementExists",
            target: Locator(criteria: [], computedNameContains: "Submit"),
            value: "some-value",
            timeout: 5.0
        )
        let data = try JSONEncoder().encode(condition)
        let decoded = try JSONDecoder().decode(RecipeWaitCondition.self, from: data)
        #expect(decoded.condition == "elementExists")
        #expect(decoded.value == "some-value")
        #expect(decoded.timeout == 5.0)
        #expect(decoded.target?.computedNameContains == "Submit")
    }

    @Test("RecipeWaitCondition with nil optional fields")
    func recipeWaitConditionNilFields() throws {
        let condition = RecipeWaitCondition(
            condition: "urlChanged",
            target: nil,
            value: nil,
            timeout: nil
        )
        let data = try JSONEncoder().encode(condition)
        let decoded = try JSONDecoder().decode(RecipeWaitCondition.self, from: data)
        #expect(decoded.condition == "urlChanged")
        #expect(decoded.target == nil)
        #expect(decoded.value == nil)
        #expect(decoded.timeout == nil)
    }

    // MARK: - RecipeStep

    @Test("RecipeStep Codable round-trip")
    func recipeStepCodable() throws {
        let step = RecipeStep(
            id: 1,
            action: "click",
            target: Locator(criteria: [], computedNameContains: "OK"),
            params: ["text": "hello"],
            waitAfter: RecipeWaitCondition(condition: "delay", target: nil, value: nil, timeout: 2.0),
            note: "Click the OK button",
            onFailure: "skip"
        )
        let data = try JSONEncoder().encode(step)
        let decoded = try JSONDecoder().decode(RecipeStep.self, from: data)
        #expect(decoded.id == 1)
        #expect(decoded.action == "click")
        #expect(decoded.target?.computedNameContains == "OK")
        #expect(decoded.params?["text"] == "hello")
        #expect(decoded.waitAfter?.condition == "delay")
        #expect(decoded.waitAfter?.timeout == 2.0)
        #expect(decoded.note == "Click the OK button")
        #expect(decoded.onFailure == "skip")
    }

    @Test("RecipeStep snake_case CodingKeys decode correctly")
    func recipeStepSnakeCaseKeys() throws {
        let json = """
        {
            "id": 2,
            "action": "type",
            "wait_after": {"condition": "delay", "timeout": 1.0},
            "on_failure": "stop"
        }
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(RecipeStep.self, from: data)
        #expect(decoded.id == 2)
        #expect(decoded.action == "type")
        #expect(decoded.waitAfter?.condition == "delay")
        #expect(decoded.waitAfter?.timeout == 1.0)
        #expect(decoded.onFailure == "stop")
    }

    // MARK: - Recipe

    @Test("Recipe Codable round-trip")
    func recipeCodable() throws {
        let recipe = Recipe(
            schemaVersion: 2,
            name: "send-slack-message",
            description: "Sends a message in Slack",
            app: "Slack",
            params: ["channel": RecipeParam(type: "string", description: "Channel", required: true)],
            preconditions: RecipePreconditions(appRunning: "Slack", urlContains: nil),
            steps: [
                RecipeStep(
                    id: 1,
                    action: "click",
                    target: Locator(criteria: [], computedNameContains: "Message"),
                    params: nil,
                    waitAfter: nil,
                    note: "Click message field",
                    onFailure: nil
                ),
            ],
            onFailure: "stop"
        )
        let data = try JSONEncoder().encode(recipe)
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)
        #expect(decoded.schemaVersion == 2)
        #expect(decoded.name == "send-slack-message")
        #expect(decoded.description == "Sends a message in Slack")
        #expect(decoded.app == "Slack")
        #expect(decoded.params?["channel"]?.type == "string")
        #expect(decoded.preconditions?.appRunning == "Slack")
        #expect(decoded.steps.count == 1)
        #expect(decoded.steps[0].id == 1)
        #expect(decoded.onFailure == "stop")
    }

    @Test("Recipe snake_case CodingKeys decode correctly")
    func recipeSnakeCaseKeys() throws {
        let json = """
        {
            "schema_version": 2,
            "name": "test-recipe",
            "description": "A test",
            "steps": [],
            "on_failure": "skip"
        }
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)
        #expect(decoded.schemaVersion == 2)
        #expect(decoded.name == "test-recipe")
        #expect(decoded.onFailure == "skip")
        #expect(decoded.app == nil)
        #expect(decoded.params == nil)
        #expect(decoded.preconditions == nil)
    }
}
