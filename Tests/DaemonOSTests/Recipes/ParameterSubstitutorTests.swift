// ParameterSubstitutorTests.swift - Unit tests for ParameterSubstitutor

import Foundation
import Testing
@testable import DaemonOS

@Suite("ParameterSubstitutor Tests")
struct ParameterSubstitutorTests {

    // MARK: - substituteString

    @Test("Single param substitution in a string")
    func singleParamSubstitution() {
        let result = ParameterSubstitutor.substituteString(
            "Hello, {{name}}!",
            with: ["name": "World"]
        )
        #expect(result == "Hello, World!")
    }

    @Test("Multiple params in one string")
    func multipleParamsInOneString() {
        let result = ParameterSubstitutor.substituteString(
            "{{greeting}}, {{name}}! Welcome to {{place}}.",
            with: ["greeting": "Hi", "name": "Alice", "place": "Wonderland"]
        )
        #expect(result == "Hi, Alice! Welcome to Wonderland.")
    }

    @Test("Missing params left as-is")
    func missingParamsLeftAsIs() {
        let result = ParameterSubstitutor.substituteString(
            "Hello, {{unknown}}!",
            with: ["name": "World"]
        )
        #expect(result == "Hello, {{unknown}}!")
    }

    @Test("String with no placeholders returns unchanged")
    func noPlaceholders() {
        let result = ParameterSubstitutor.substituteString(
            "No placeholders here",
            with: ["key": "value"]
        )
        #expect(result == "No placeholders here")
    }

    @Test("Empty values dictionary returns input unchanged")
    func emptyValues() {
        let result = ParameterSubstitutor.substituteString(
            "Keep {{this}}",
            with: [:]
        )
        #expect(result == "Keep {{this}}")
    }

    // MARK: - substitute (step params)

    @Test("Nil stepParams returns nil")
    func nilStepParamsReturnsNil() {
        let result = ParameterSubstitutor.substitute(nil, with: ["key": "value"])
        #expect(result == nil)
    }

    @Test("Substitutes values in step params dictionary")
    func substituteStepParams() {
        let stepParams = ["text": "Hello {{name}}", "channel": "{{channel}}"]
        let result = ParameterSubstitutor.substitute(
            stepParams,
            with: ["name": "Bob", "channel": "general"]
        )
        #expect(result?["text"] == "Hello Bob")
        #expect(result?["channel"] == "general")
    }

    @Test("Step params with missing values leaves placeholders intact")
    func substituteStepParamsMissing() {
        let stepParams = ["text": "{{known}} and {{unknown}}"]
        let result = ParameterSubstitutor.substitute(
            stepParams,
            with: ["known": "resolved"]
        )
        #expect(result?["text"] == "resolved and {{unknown}}")
    }

    @Test("Empty step params returns empty dictionary")
    func emptyStepParams() {
        let result = ParameterSubstitutor.substitute([:], with: ["key": "value"])
        #expect(result != nil)
        #expect(result?.isEmpty == true)
    }

    // MARK: - substituteWaitAfter

    @Test("substituteWaitAfter replaces value placeholder")
    func substituteWaitAfterValue() {
        let waitAfter = RecipeWaitCondition(
            condition: "urlContains",
            target: nil,
            value: "https://{{domain}}/home",
            timeout: 10.0
        )
        let result = ParameterSubstitutor.substituteWaitAfter(
            waitAfter,
            with: ["domain": "example.com"]
        )
        #expect(result.condition == "urlContains")
        #expect(result.value == "https://example.com/home")
        #expect(result.timeout == 10.0)
        #expect(result.target == nil)
    }

    @Test("substituteWaitAfter with nil value returns unchanged condition")
    func substituteWaitAfterNilValue() {
        let waitAfter = RecipeWaitCondition(
            condition: "delay",
            target: nil,
            value: nil,
            timeout: 3.0
        )
        let result = ParameterSubstitutor.substituteWaitAfter(
            waitAfter,
            with: ["key": "value"]
        )
        #expect(result.condition == "delay")
        #expect(result.value == nil)
        #expect(result.timeout == 3.0)
    }

    @Test("substituteWaitAfter preserves condition and timeout")
    func substituteWaitAfterPreservesFields() {
        let waitAfter = RecipeWaitCondition(
            condition: "elementExists",
            target: nil,
            value: "{{buttonLabel}}",
            timeout: 5.0
        )
        let result = ParameterSubstitutor.substituteWaitAfter(
            waitAfter,
            with: ["buttonLabel": "Submit"]
        )
        #expect(result.condition == "elementExists")
        #expect(result.value == "Submit")
        #expect(result.timeout == 5.0)
    }
}
