// ObserverManagerTests.swift - Unit tests for ObserverManager

import Foundation
import Testing
@testable import DaemonOS

@Suite("ObserverManager")
struct ObserverManagerTests {

    @Test("subscribe returns a UUID token")
    func subscribeReturnsToken() {
        let manager = ObserverManager.shared
        manager.cleanup()

        let token = manager.subscribe(pid: 1, notification: "AXValueChanged") {}
        #expect(token != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        manager.cleanup()
    }

    @Test("activeCount increments after subscribe")
    func activeCountIncrements() {
        let manager = ObserverManager.shared
        manager.cleanup()

        #expect(manager.activeCount == 0)

        _ = manager.subscribe(pid: 1, notification: "AXValueChanged") {}
        #expect(manager.activeCount == 1)

        _ = manager.subscribe(pid: 2, notification: "AXFocusedUIElementChanged") {}
        #expect(manager.activeCount == 2)

        manager.cleanup()
    }

    @Test("unsubscribe removes the subscription")
    func unsubscribeRemoves() {
        let manager = ObserverManager.shared
        manager.cleanup()

        let token = manager.subscribe(pid: 1, notification: "AXValueChanged") {}
        #expect(manager.activeCount == 1)

        manager.unsubscribe(token: token)
        #expect(manager.activeCount == 0)
    }

    @Test("unsubscribe with unknown token does not crash")
    func unsubscribeUnknownToken() {
        let manager = ObserverManager.shared
        manager.cleanup()

        _ = manager.subscribe(pid: 1, notification: "AXValueChanged") {}
        manager.unsubscribe(token: UUID())
        #expect(manager.activeCount == 1)

        manager.cleanup()
    }

    @Test("cleanup clears all subscriptions")
    func cleanupClearsAll() {
        let manager = ObserverManager.shared
        manager.cleanup()

        _ = manager.subscribe(pid: 1, notification: "AXValueChanged") {}
        _ = manager.subscribe(pid: 2, notification: "AXFocusedUIElementChanged") {}
        _ = manager.subscribe(pid: 3, notification: "AXTitleChanged") {}
        #expect(manager.activeCount == 3)

        manager.cleanup()
        #expect(manager.activeCount == 0)
    }
}
