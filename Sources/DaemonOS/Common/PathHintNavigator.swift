// PathHintNavigator.swift - AXorcist path navigation hints for faster re-finds

import AXorcist
import Foundation

/// Stores path hints from successful element finds for faster subsequent lookups.
/// When the same element is needed again (recipe step retries, readback),
/// the stored path hint can skip the full tree walk.
public final class PathHintNavigator: @unchecked Sendable {

    /// Shared instance.
    public static let shared = PathHintNavigator()

    private var hints: [Int: PathHint] = [:]
    private let lock = NSLock()

    private struct PathHint {
        let locatorHash: Int
        let pathDescription: String
        let timestamp: Date
    }

    /// TTL for stored hints (10s default — UI layout rarely changes that fast).
    public var ttl: TimeInterval = 10.0

    private init() {}

    /// Store a path hint after a successful element find.
    public func storeHint(locatorHash: Int, pathDescription: String) {
        lock.lock()
        hints[locatorHash] = PathHint(
            locatorHash: locatorHash,
            pathDescription: pathDescription,
            timestamp: Date()
        )
        lock.unlock()
    }

    /// Retrieve a path hint for a locator hash, if still valid.
    public func getHint(locatorHash: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }

        guard let hint = hints[locatorHash] else { return nil }

        if Date().timeIntervalSince(hint.timestamp) > ttl {
            hints.removeValue(forKey: locatorHash)
            return nil
        }

        return hint.pathDescription
    }

    /// Clear all stored hints.
    public func clearAll() {
        lock.lock()
        hints.removeAll()
        lock.unlock()
    }

    /// Number of stored hints (for testing).
    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return hints.count
    }
}
