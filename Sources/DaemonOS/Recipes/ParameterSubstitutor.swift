// ParameterSubstitutor.swift - Recipe parameter substitution

import Foundation

/// Handles {{param}} placeholder substitution in recipe steps.
public enum ParameterSubstitutor {

    /// Replace {{param}} placeholders in step params with actual values.
    public static func substitute(
        _ stepParams: [String: String]?,
        with values: [String: String]
    ) -> [String: String]? {
        guard let stepParams else { return nil }
        var resolved: [String: String] = [:]
        for (key, value) in stepParams {
            resolved[key] = substituteString(value, with: values)
        }
        return resolved
    }

    /// Replace {{param}} placeholders in a wait_after condition's value.
    public static func substituteWaitAfter(
        _ waitAfter: RecipeWaitCondition,
        with values: [String: String]
    ) -> RecipeWaitCondition {
        guard var value = waitAfter.value else { return waitAfter }
        value = substituteString(value, with: values)
        return RecipeWaitCondition(
            condition: waitAfter.condition,
            target: waitAfter.target,
            value: value,
            timeout: waitAfter.timeout
        )
    }

    /// Replace all {{paramName}} occurrences in a string.
    public static func substituteString(
        _ input: String,
        with values: [String: String]
    ) -> String {
        var result = input
        for (paramName, paramValue) in values {
            result = result.replacingOccurrences(of: "{{\(paramName)}}", with: paramValue)
        }
        return result
    }
}
