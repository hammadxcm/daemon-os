// ElementCache.swift - TTL-based element caching for repeated access

import AXorcist
import Foundation

/// Caches recently-found elements by locator hash for repeated access.
/// Short-lived TTL (2s default) since UI elements go stale quickly.
public final class ElementCache: @unchecked Sendable {

    /// Shared instance.
    public static let shared = ElementCache()

    private var cache: [Int: CacheEntry] = [:]
    private let lock = NSLock()

    /// Default time-to-live for cached elements.
    public var ttl: TimeInterval = 2.0

    private struct CacheEntry {
        let element: Element
        let timestamp: Date
    }

    private init() {}

    /// Look up a cached element by locator hash.
    public func get(hash: Int) -> Element? {
        lock.lock()
        defer { lock.unlock() }

        guard let entry = cache[hash] else { return nil }

        if Date().timeIntervalSince(entry.timestamp) > ttl {
            cache.removeValue(forKey: hash)
            return nil
        }

        return entry.element
    }

    /// Store an element in the cache.
    public func put(hash: Int, element: Element) {
        lock.lock()
        cache[hash] = CacheEntry(element: element, timestamp: Date())
        lock.unlock()
    }

    /// Invalidate all cached elements.
    public func invalidateAll() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }

    /// Remove expired entries.
    public func evictExpired() {
        lock.lock()
        let now = Date()
        cache = cache.filter { now.timeIntervalSince($0.value.timestamp) <= ttl }
        lock.unlock()
    }

    /// Number of cached entries (for testing).
    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return cache.count
    }
}
