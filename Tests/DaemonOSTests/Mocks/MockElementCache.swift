// MockElementCache.swift - Deterministic element cache for testing

import Foundation
@testable import DaemonOS

/// Deterministic element cache for testing cache-dependent code.
final class MockElementCache {
    var storage: [Int: Any] = [:]
    var hitCount = 0
    var missCount = 0

    func get(hash: Int) -> Any? {
        if let entry = storage[hash] {
            hitCount += 1
            return entry
        }
        missCount += 1
        return nil
    }

    func put(hash: Int, value: Any) {
        storage[hash] = value
    }

    func invalidateAll() {
        storage.removeAll()
    }

    func reset() {
        storage.removeAll()
        hitCount = 0
        missCount = 0
    }
}
