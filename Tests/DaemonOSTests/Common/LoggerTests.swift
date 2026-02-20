// LoggerTests.swift - Unit tests for LogLevel and Log

import Foundation
import Testing
@testable import DaemonOS

@Suite("Logger Tests")
struct LoggerTests {

    // MARK: - LogLevel ordering

    @Test("LogLevel debug < info < warn < error")
    func logLevelOrdering() {
        #expect(LogLevel.debug < LogLevel.info)
        #expect(LogLevel.info < LogLevel.warn)
        #expect(LogLevel.warn < LogLevel.error)

        // Transitive
        #expect(LogLevel.debug < LogLevel.warn)
        #expect(LogLevel.debug < LogLevel.error)
        #expect(LogLevel.info < LogLevel.error)
    }

    @Test("LogLevel is not less than itself")
    func logLevelNotLessThanSelf() {
        #expect(!(LogLevel.debug < LogLevel.debug))
        #expect(!(LogLevel.info < LogLevel.info))
        #expect(!(LogLevel.warn < LogLevel.warn))
        #expect(!(LogLevel.error < LogLevel.error))
    }

    @Test("LogLevel higher is not less than lower")
    func logLevelHigherNotLessThanLower() {
        #expect(!(LogLevel.error < LogLevel.warn))
        #expect(!(LogLevel.warn < LogLevel.info))
        #expect(!(LogLevel.info < LogLevel.debug))
    }

    // MARK: - LogLevel rawValues

    @Test("LogLevel rawValues are sequential integers")
    func logLevelRawValues() {
        #expect(LogLevel.debug.rawValue == 0)
        #expect(LogLevel.info.rawValue == 1)
        #expect(LogLevel.warn.rawValue == 2)
        #expect(LogLevel.error.rawValue == 3)
    }

    // MARK: - LogLevel labels

    @Test("LogLevel labels are correct strings")
    func logLevelLabels() {
        #expect(LogLevel.debug.label == "DEBUG")
        #expect(LogLevel.info.label == "INFO")
        #expect(LogLevel.warn.label == "WARN")
        #expect(LogLevel.error.label == "ERROR")
    }

    // MARK: - Log.minimumLevel filtering

    @Test("Log.minimumLevel set to .warn suppresses debug and info")
    func minimumLevelFiltering() {
        // Save original level to restore after test
        let original = Log.minimumLevel
        defer { Log.minimumLevel = original }

        Log.minimumLevel = .warn

        // Verify the filtering concept: debug and info are below warn
        #expect(LogLevel.debug < Log.minimumLevel)
        #expect(LogLevel.info < Log.minimumLevel)

        // warn and error should pass the filter
        #expect(!(LogLevel.warn < Log.minimumLevel))
        #expect(!(LogLevel.error < Log.minimumLevel))
    }

    @Test("Log.minimumLevel set to .debug allows all levels")
    func minimumLevelDebugAllowsAll() {
        let original = Log.minimumLevel
        defer { Log.minimumLevel = original }

        Log.minimumLevel = .debug

        // All levels should be >= debug
        #expect(!(LogLevel.debug < Log.minimumLevel))
        #expect(!(LogLevel.info < Log.minimumLevel))
        #expect(!(LogLevel.warn < Log.minimumLevel))
        #expect(!(LogLevel.error < Log.minimumLevel))
    }

    @Test("Log.minimumLevel set to .error suppresses all but error")
    func minimumLevelErrorSuppressesOthers() {
        let original = Log.minimumLevel
        defer { Log.minimumLevel = original }

        Log.minimumLevel = .error

        #expect(LogLevel.debug < Log.minimumLevel)
        #expect(LogLevel.info < Log.minimumLevel)
        #expect(LogLevel.warn < Log.minimumLevel)
        #expect(!(LogLevel.error < Log.minimumLevel))
    }

    @Test("Log.minimumLevel can be changed at runtime")
    func minimumLevelMutable() {
        let original = Log.minimumLevel
        defer { Log.minimumLevel = original }

        Log.minimumLevel = .debug
        #expect(Log.minimumLevel == .debug)

        Log.minimumLevel = .error
        #expect(Log.minimumLevel == .error)
    }
}
