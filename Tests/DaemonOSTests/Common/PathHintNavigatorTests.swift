// PathHintNavigatorTests.swift - Unit tests for PathHintNavigator

import Foundation
import Testing
@testable import DaemonOS

@Suite("PathHintNavigator")
struct PathHintNavigatorTests {

    @Test("Store and retrieve hint")
    func storeAndRetrieve() {
        let nav = PathHintNavigator.shared
        nav.clearAll()

        nav.storeHint(locatorHash: 42, pathDescription: "AXWindow > AXButton[OK]")
        let hint = nav.getHint(locatorHash: 42)
        #expect(hint == "AXWindow > AXButton[OK]")

        nav.clearAll()
    }

    @Test("getHint returns nil for unknown hash")
    func missOnUnknownHash() {
        let nav = PathHintNavigator.shared
        nav.clearAll()

        #expect(nav.getHint(locatorHash: 9999) == nil)
    }

    @Test("TTL expiry causes hint miss")
    func ttlExpiry() async throws {
        let nav = PathHintNavigator.shared
        nav.clearAll()

        let originalTTL = nav.ttl
        defer { nav.ttl = originalTTL }

        nav.ttl = 0.05 // 50ms
        nav.storeHint(locatorHash: 100, pathDescription: "AXWindow > AXTextField")

        // Wait for TTL to expire
        try await Task.sleep(for: .milliseconds(100))

        #expect(nav.getHint(locatorHash: 100) == nil)
    }

    @Test("clearAll removes all hints")
    func clearAllWorks() {
        let nav = PathHintNavigator.shared
        nav.clearAll()

        nav.storeHint(locatorHash: 1, pathDescription: "path1")
        nav.storeHint(locatorHash: 2, pathDescription: "path2")
        nav.storeHint(locatorHash: 3, pathDescription: "path3")
        #expect(nav.count == 3)

        nav.clearAll()
        #expect(nav.count == 0)
    }
}
