// ErrorBuilderTests.swift - Unit tests for ErrorBuilder

import Testing
@testable import DaemonOS

@Suite("ErrorBuilder")
struct ErrorBuilderTests {

    @Test("wrap includes context in error message")
    func wrapWithContext() {
        let underlyingError = DaemonError.appNotFound(name: "Safari")
        let result = ErrorBuilder.wrap(underlyingError, context: "Focus failed")

        #expect(result.success == false)
        #expect(result.error?.contains("Focus failed") == true)
        #expect(result.suggestion == nil)
    }

    @Test("wrap includes suggestion when provided")
    func wrapWithSuggestion() {
        let underlyingError = DaemonError.timeout(seconds: 10)
        let result = ErrorBuilder.wrap(
            underlyingError,
            context: "Wait timed out",
            suggestion: "Try increasing the timeout"
        )

        #expect(result.success == false)
        #expect(result.error?.contains("Wait timed out") == true)
        #expect(result.suggestion == "Try increasing the timeout")
    }

    @Test("wrap includes underlying error description")
    func wrapIncludesErrorDescription() {
        let underlyingError = DaemonError.elementNotFound(description: "OK button")
        let result = ErrorBuilder.wrap(underlyingError, context: "Click action")

        #expect(result.error?.contains("OK button") == true)
    }
}
