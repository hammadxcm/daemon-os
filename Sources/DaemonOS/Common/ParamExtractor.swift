// ParamExtractor.swift - Type-safe parameter extraction from MCP tool arguments

import Foundation

/// Extracts typed values from MCP tool argument dictionaries.
public struct ParamExtractor: Sendable {
    private let args: [String: Any]

    public init(_ args: [String: Any]) {
        self.args = args
    }

    public func string(_ key: String) -> String? {
        args[key] as? String
    }

    public func int(_ key: String) -> Int? {
        if let i = args[key] as? Int { return i }
        if let d = args[key] as? Double { return Int(d) }
        return nil
    }

    public func double(_ key: String) -> Double? {
        if let d = args[key] as? Double { return d }
        if let i = args[key] as? Int { return Double(i) }
        return nil
    }

    public func bool(_ key: String) -> Bool? {
        args[key] as? Bool
    }

    public func stringArray(_ key: String) -> [String]? {
        args[key] as? [String]
    }

    /// Require a string value, returning nil and providing an error ToolResult if missing.
    public func require(_ key: String) -> (value: String?, error: ToolResult?) {
        if let value = string(key) {
            return (value, nil)
        }
        return (nil, ToolResult(success: false, error: "Missing required parameter: \(key)"))
    }
}
