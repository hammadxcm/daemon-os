// ElementCacheTests.swift - Unit tests for ElementCache

import ApplicationServices
import AXorcist
import Foundation
import Testing
@testable import DaemonOS

@Suite("ElementCache")
struct ElementCacheTests {

    /// Helper: create a dummy Element wrapping the system-wide AXUIElement.
    private func makeDummyElement() -> Element {
        Element(AXUIElementCreateSystemWide())
    }

    @Test("Cache starts empty")
    func startsEmpty() {
        let cache = ElementCache.shared
        cache.invalidateAll()
        #expect(cache.count == 0)
    }

    @Test("put and get round-trip")
    func putAndGet() {
        let cache = ElementCache.shared
        cache.invalidateAll()

        let element = makeDummyElement()
        cache.put(hash: 42, element: element)

        let retrieved = cache.get(hash: 42)
        #expect(retrieved != nil)
        #expect(cache.count == 1)
    }

    @Test("get returns nil for unknown hash")
    func getMiss() {
        let cache = ElementCache.shared
        cache.invalidateAll()
        #expect(cache.get(hash: 9999) == nil)
    }

    @Test("TTL expiry causes cache miss")
    func ttlExpiry() async throws {
        let cache = ElementCache.shared
        cache.invalidateAll()

        let originalTTL = cache.ttl
        defer { cache.ttl = originalTTL }

        cache.ttl = 0.05 // 50ms
        cache.put(hash: 100, element: makeDummyElement())

        // Wait for TTL to expire
        try await Task.sleep(for: .milliseconds(100))

        #expect(cache.get(hash: 100) == nil)
    }

    @Test("invalidateAll clears all entries")
    func invalidateAll() {
        let cache = ElementCache.shared
        cache.invalidateAll()

        cache.put(hash: 1, element: makeDummyElement())
        cache.put(hash: 2, element: makeDummyElement())
        cache.put(hash: 3, element: makeDummyElement())
        #expect(cache.count == 3)

        cache.invalidateAll()
        #expect(cache.count == 0)
    }

    @Test("evictExpired removes stale entries but keeps fresh ones")
    func evictExpired() async throws {
        let cache = ElementCache.shared
        cache.invalidateAll()

        let originalTTL = cache.ttl
        defer { cache.ttl = originalTTL }

        cache.ttl = 0.05 // 50ms
        cache.put(hash: 10, element: makeDummyElement())

        // Wait for this entry to expire
        try await Task.sleep(for: .milliseconds(100))

        // Add a fresh entry
        cache.ttl = 5.0
        cache.put(hash: 20, element: makeDummyElement())

        // Set TTL back to short so eviction considers the first entry stale
        cache.ttl = 0.05
        cache.evictExpired()

        // Stale entry removed, fresh entry remains
        #expect(cache.get(hash: 10) == nil)
        // Restore a reasonable TTL so the fresh entry is still valid for get()
        cache.ttl = 5.0
        #expect(cache.get(hash: 20) != nil)
    }
}
