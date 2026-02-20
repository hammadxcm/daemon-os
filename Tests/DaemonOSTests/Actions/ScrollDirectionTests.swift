// ScrollDirectionTests.swift - Unit tests for ScrollHandler direction validation

import Testing
@testable import DaemonOS

@Suite("Scroll Direction")
struct ScrollDirectionTests {

    @Test("scroll with invalid direction returns error")
    func invalidDirection() {
        let result = ScrollHandler.scroll(
            direction: "diagonal",
            amount: nil,
            appName: nil,
            x: nil,
            y: nil
        )
        #expect(result.success == false)
        #expect(result.error?.contains("Invalid direction") == true)
    }

    @Test("scroll with empty direction returns error")
    func emptyDirection() {
        let result = ScrollHandler.scroll(
            direction: "",
            amount: nil,
            appName: nil,
            x: nil,
            y: nil
        )
        #expect(result.success == false)
    }
}
