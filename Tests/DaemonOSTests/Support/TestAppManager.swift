// TestAppManager.swift - Launch/teardown test apps for integration tests

import AppKit
import Foundation
@testable import DaemonOS

/// Manages test app lifecycle for integration tests (AXorcist-inspired pattern).
enum TestAppManager {

    /// Ensure TextEdit is running and return its PID.
    @MainActor
    static func ensureTextEditRunning() async -> pid_t? {
        if let app = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == "com.apple.TextEdit"
        }) {
            return app.processIdentifier
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        do {
            let app = try await NSWorkspace.shared.openApplication(
                at: URL(fileURLWithPath: "/System/Applications/TextEdit.app"),
                configuration: config
            )
            // Wait for app to be ready
            try await Task.sleep(nanoseconds: 1_000_000_000)
            return app.processIdentifier
        } catch {
            return nil
        }
    }

    /// Close TextEdit.
    static func closeTextEdit() {
        if let app = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == "com.apple.TextEdit"
        }) {
            app.terminate()
        }
    }

    /// Ensure Finder is running and return its PID.
    static func ensureFinderRunning() -> pid_t? {
        NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == "com.apple.finder"
        })?.processIdentifier
    }
}
