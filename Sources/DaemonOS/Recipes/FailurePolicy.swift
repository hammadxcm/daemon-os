// FailurePolicy.swift - Type-safe failure policy enum

import Foundation

/// How to handle a failed recipe step.
public enum FailurePolicy: String, Codable, Sendable {
    case stop
    case skip
}
