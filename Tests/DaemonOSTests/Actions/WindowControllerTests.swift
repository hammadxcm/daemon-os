// WindowControllerTests.swift - Unit tests for WindowController validation

import Testing
@testable import DaemonOS

@Suite("WindowController")
struct WindowControllerTests {

    @Test("manageWindow with nonexistent app returns error")
    func nonexistentApp() {
        let result = WindowController.manageWindow(
            action: "minimize",
            appName: "NonExistentAppXYZ12345",
            windowTitle: nil,
            x: nil, y: nil,
            width: nil, height: nil
        )
        #expect(result.success == false)
        #expect(result.error?.contains("not found") == true)
    }

    @Test("unknown action returns error for nonexistent app")
    func unknownAction() {
        let result = WindowController.manageWindow(
            action: "explode",
            appName: "NonExistentAppXYZ12345",
            windowTitle: nil,
            x: nil, y: nil,
            width: nil, height: nil
        )
        #expect(result.success == false)
    }
}
