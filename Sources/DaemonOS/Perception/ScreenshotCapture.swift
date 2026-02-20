// ScreenshotCapture.swift - Sync screenshot bridge for daemon_screenshot
//
// Extracted from Perception.swift. Bridges ScreenCaptureKit's async API
// to synchronous using RunLoop spinning.

import AppKit
import Foundation

/// Synchronous screenshot capture bridge.
enum ScreenshotCapture {

    /// Guard against orphan ScreenCaptureKit tasks. If a previous capture is
    /// still in-flight (hung or slow), we refuse to start another one rather
    /// than crashing the server.
    private static var isCapturing = false

    /// Bridge ScreenCaptureKit's async API to synchronous using RunLoop spinning.
    /// ScreenCaptureKit REQUIRES the main thread (CG-initialized). Without
    /// @MainActor, Task {} may run on a background thread and crash with
    /// CGS_REQUIRE_INIT.
    static func captureScreenshotSync(
        pid: pid_t,
        fullResolution: Bool
    ) -> ScreenshotResult? {
        // Permission check (fail-fast)
        guard ScreenCapture.hasPermission() else {
            Log.error("Screenshot: Screen Recording permission not granted")
            return nil
        }

        // Guard against concurrent captures (orphan tasks from previous calls)
        guard !isCapturing else {
            Log.warn("Screenshot: capture already in-flight, skipping")
            return nil
        }
        isCapturing = true
        defer { isCapturing = false }

        var result: ScreenshotResult?
        var completed = false

        // Fire async capture on MainActor. ScreenCaptureKit REQUIRES a
        // CG-initialized thread (the main thread). Without @MainActor,
        // Task {} runs on a cooperative thread pool and crashes.
        Task { @MainActor in
            result = await ScreenCapture.captureWindow(
                pid: pid, fullResolution: fullResolution
            )
            completed = true
        }

        // Spin RunLoop.main until async task completes.
        // Each 10ms iteration processes events including Task continuations.
        let deadline = Date().addingTimeInterval(10)
        while !completed && Date() < deadline {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
        }

        if !completed {
            Log.error("Screenshot: timed out after 10s")
        }

        return result
    }
}
