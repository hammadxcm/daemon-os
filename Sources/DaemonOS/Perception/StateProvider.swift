// StateProvider.swift - App state building for daemon_state
//
// Extracted from Perception.swift. Builds app info dictionaries
// with window positions and sizes.

import AppKit
import AXorcist
import Foundation

/// Builds app state info for daemon_state.
enum StateProvider {

    /// Build info dictionary for a running application.
    static func buildAppInfo(_ app: NSRunningApplication) -> [String: Any] {
        var info: [String: Any] = [
            "name": app.localizedName ?? "Unknown",
            "bundle_id": app.bundleIdentifier ?? "unknown",
            "pid": app.processIdentifier,
            "active": app.isActive,
        ]

        if let appElement = Element.application(for: app.processIdentifier) {
            if let windows = appElement.windows() {
                let windowInfos: [[String: Any]] = windows.compactMap { win in
                    var w: [String: Any] = [:]
                    if let title = win.title() { w["title"] = title }
                    if let pos = win.position() { w["position"] = ["x": pos.x, "y": pos.y] }
                    if let size = win.size() { w["size"] = ["width": size.width, "height": size.height] }
                    return w.isEmpty ? nil : w
                }
                if !windowInfos.isEmpty {
                    info["windows"] = windowInfos
                }
            }
        }

        return info
    }
}
