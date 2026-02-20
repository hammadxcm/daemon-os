// ErrorBuilder.swift - Contextual error wrapping (AXorcist pattern)

import Foundation

/// Helpers for building error ToolResults with context.
public enum ErrorBuilder {
    /// Wraps a system error with daemon-specific context and suggestion.
    public static func wrap(
        _ error: any Error,
        context: String,
        suggestion: String? = nil
    ) -> ToolResult {
        let description: String
        if let daemonError = error as? DaemonError {
            description = daemonError.localizedDescription
        } else {
            description = String(describing: error)
        }
        return ToolResult(
            success: false,
            error: "\(context): \(description)",
            suggestion: suggestion
        )
    }
}
