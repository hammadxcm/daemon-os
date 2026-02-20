// AppResolver.swift - Shared app resolution logic

import AppKit
import AXorcist
import Foundation

/// Deduplicated app resolution used across Perception, Actions, Wait, and Focus modules.
public enum AppResolver {

    /// Find a running app by name (case-insensitive, contains match).
    public static func findApp(named name: String) -> NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first {
            $0.localizedName?.localizedCaseInsensitiveContains(name) == true
        }
    }

    /// Get the AXorcist Element for a named app.
    public static func appElement(for name: String) -> Element? {
        guard let app = findApp(named: name) else { return nil }
        return Element.application(for: app.processIdentifier)
    }

    /// Resolve an optional app name to an Element.
    /// If appName is provided, looks up that app. Otherwise returns the frontmost app.
    public static func resolve(appName: String?) -> Element? {
        if let appName {
            return appElement(for: appName)
        }
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return nil }
        return Element.application(for: frontApp.processIdentifier)
    }
}
