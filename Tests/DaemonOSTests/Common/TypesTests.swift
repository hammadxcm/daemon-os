// TypesTests.swift - Unit tests for core shared types

import Testing
@testable import DaemonOS

@Suite("Core Types")
struct TypesTests {

    @Test("DaemonOS version is 1.0.0")
    func version() {
        #expect(DaemonOS.version == "1.0.0")
    }

    @Test("DaemonOS name is daemon-os")
    func name() {
        #expect(DaemonOS.name == "daemon-os")
    }

    @Test("ToolResult success toDict includes success key")
    func toolResultSuccessToDict() {
        let result = ToolResult(success: true, data: ["key": "value"])
        let dict = result.toDict()
        #expect(dict["success"] as? Bool == true)
        #expect((dict["data"] as? [String: Any])?["key"] as? String == "value")
    }

    @Test("ToolResult failure toDict includes error")
    func toolResultFailureToDict() {
        let result = ToolResult(success: false, error: "something broke", suggestion: "fix it")
        let dict = result.toDict()
        #expect(dict["success"] as? Bool == false)
        #expect(dict["error"] as? String == "something broke")
        #expect(dict["suggestion"] as? String == "fix it")
    }

    @Test("ToolResult toDict omits nil fields")
    func toolResultOmitsNils() {
        let result = ToolResult(success: true)
        let dict = result.toDict()
        #expect(dict["data"] == nil)
        #expect(dict["error"] == nil)
        #expect(dict["suggestion"] == nil)
        #expect(dict["context"] == nil)
    }

    @Test("ContextInfo toDict")
    func contextInfoToDict() {
        let info = ContextInfo(app: "Finder", window: "Desktop", url: "https://example.com")
        let dict = info.toDict()
        #expect(dict["app"] as? String == "Finder")
        #expect(dict["window"] as? String == "Desktop")
        #expect(dict["url"] as? String == "https://example.com")
    }

    @Test("ContextInfo toDict omits nil fields")
    func contextInfoOmitsNils() {
        let info = ContextInfo()
        let dict = info.toDict()
        #expect(dict.isEmpty)
    }

    @Test("ScreenshotResult default mimeType is image/png")
    func screenshotResultDefaults() {
        let result = ScreenshotResult(base64PNG: "abc", width: 100, height: 200)
        #expect(result.mimeType == "image/png")
        #expect(result.windowTitle == nil)
    }

    @Test("DaemonError localizedDescription includes details")
    func daemonErrorDescriptions() {
        #expect(DaemonError.timeout(seconds: 10).localizedDescription.contains("10"))
        #expect(DaemonError.elementNotFound(description: "button").localizedDescription.contains("button"))
        #expect(DaemonError.actionFailed(description: "click").localizedDescription.contains("click"))
        #expect(DaemonError.appNotFound(name: "Safari").localizedDescription.contains("Safari"))
        #expect(DaemonError.permissionDenied("no access").localizedDescription.contains("no access"))
        #expect(DaemonError.invalidParameter("bad param").localizedDescription.contains("bad param"))
    }

    @Test("DaemonConstants has expected values")
    func constants() {
        #expect(DaemonConstants.semanticDepthBudget == 25)
        #expect(DaemonConstants.maxSearchDepth == 100)
        #expect(DaemonConstants.defaultTimeoutSeconds == 30)
        #expect(DaemonConstants.defaultPollInterval == 0.5)
    }
}
