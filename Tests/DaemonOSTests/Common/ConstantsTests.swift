// ConstantsTests.swift - Unit tests for Constants (Timing and Limits)

import Testing
@testable import DaemonOS

@Suite("Constants")
struct ConstantsTests {

    // MARK: - Timing values are positive

    @Test("All Timing TimeInterval values are positive")
    func timingTimeIntervalsPositive() {
        #expect(Timing.appFocusDelay > 0)
        #expect(Timing.syntheticClickDelay > 0)
        #expect(Timing.typeCharDelay > 0)
        #expect(Timing.focusRetryDelay > 0)
        #expect(Timing.focusRetryLongDelay > 0)
        #expect(Timing.screenshotPollInterval > 0)
        #expect(Timing.screenshotDeadline > 0)
        #expect(Timing.clearFieldDelay > 0)
        #expect(Timing.focusElementDelay > 0)
        #expect(Timing.readbackDelay > 0)
        #expect(Timing.recipeFocusDelay > 0)
    }

    @Test("All Timing UInt32 values are positive")
    func timingUInt32ValuesPositive() {
        #expect(Timing.axNativeReactionDelay > 0)
        #expect(Timing.modifierClearDelay > 0)
        #expect(Timing.hotkeyProcessDelay > 0)
        #expect(Timing.setValueDelay > 0)
    }

    // MARK: - Limits values are positive and reasonable

    @Test("All Limits values are positive")
    func limitsPositive() {
        #expect(Limits.semanticDepthBudget > 0)
        #expect(Limits.maxSearchDepth > 0)
        #expect(Limits.domIdSearchDepth > 0)
        #expect(Limits.waitElementSearchDepth > 0)
        #expect(Limits.contextInteractiveDepth > 0)
        #expect(Limits.scrollableSearchDepth > 0)
        #expect(Limits.maxSearchResults > 0)
        #expect(Limits.maxInteractiveElements > 0)
        #expect(Limits.maxFieldCandidates > 0)
        #expect(Limits.valueDisplayTruncation > 0)
        #expect(Limits.readbackTruncation > 0)
        #expect(Limits.maxScreenshotWidth > 0)
        #expect(Limits.webAreaSearchDepth > 0)
    }

    @Test("maxSearchDepth is at least as large as semanticDepthBudget")
    func maxSearchDepthCoversSemanticBudget() {
        #expect(Limits.maxSearchDepth >= Limits.semanticDepthBudget)
    }

    @Test("domIdSearchDepth does not exceed maxSearchDepth")
    func domIdWithinMax() {
        #expect(Limits.domIdSearchDepth <= Limits.maxSearchDepth)
    }

    @Test("maxScreenshotWidth is within a reasonable range")
    func screenshotWidthReasonable() {
        #expect(Limits.maxScreenshotWidth >= 640)
        #expect(Limits.maxScreenshotWidth <= 7680)
    }

    // MARK: - No zero defaults

    @Test("screenshotDeadline is not zero")
    func screenshotDeadlineNonZero() {
        #expect(Timing.screenshotDeadline != 0)
    }

    @Test("semanticDepthBudget is not zero")
    func semanticDepthBudgetNonZero() {
        #expect(Limits.semanticDepthBudget != 0)
    }
}
