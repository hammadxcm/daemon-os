// ContextProvider.swift - Context building for daemon_context
//
// Extracted from Perception.swift. Builds orientation context:
// focused app, window, URL, focused element, visible interactive elements.

import AppKit
import AXorcist
import Foundation

/// Builds orientation context for daemon_context.
enum ContextProvider {

    /// Build full context for a running application.
    static func buildContext(for app: NSRunningApplication) -> ToolResult {
        let pid = app.processIdentifier
        guard let appElement = Element.application(for: pid) else {
            return ToolResult(
                success: true,
                data: [
                    "app": app.localizedName ?? "Unknown",
                    "note": "Could not read accessibility tree. App may need focus for native apps.",
                ],
                suggestion: "Try daemon_focus to bring the app to front first"
            )
        }

        var data: [String: Any] = [
            "app": app.localizedName ?? "Unknown",
            "bundle_id": app.bundleIdentifier ?? "unknown",
            "pid": pid,
        ]

        // Window title
        if let window = appElement.focusedWindow() {
            if let title = window.title() {
                data["window"] = title
            }
            // URL for browsers
            if let webArea = ElementFinder.findWebArea(in: window) {
                if let url = ElementFinder.readURL(from: webArea) {
                    data["url"] = url
                }
            }
        }

        // Focused element
        if let focused = appElement.focusedUIElement() {
            var focusedInfo: [String: Any] = [:]
            if let role = focused.role() { focusedInfo["role"] = role }
            if let title = focused.title() { focusedInfo["title"] = title }
            if let name = focused.computedName() { focusedInfo["name"] = name }
            focusedInfo["editable"] = focused.isEditable()
            if !focusedInfo.isEmpty {
                data["focused_element"] = focusedInfo
            }
        }

        // Interactive elements (buttons, links, fields - just names and roles, not full tree)
        if let window = appElement.focusedWindow() {
            let interactiveRoles: Set<String> = [
                "AXButton", "AXLink", "AXTextField", "AXTextArea",
                "AXCheckBox", "AXRadioButton", "AXPopUpButton",
                "AXComboBox", "AXMenuButton", "AXTab",
            ]
            var interactives: [[String: String]] = []
            collectInteractiveElements(
                from: window, roles: interactiveRoles,
                results: &interactives, depth: 0, maxDepth: 8
            )
            if !interactives.isEmpty {
                data["interactive_elements"] = Array(interactives.prefix(30))
            }
        }

        return ToolResult(
            success: true,
            data: data,
            context: ContextInfo(
                app: app.localizedName,
                window: data["window"] as? String,
                url: data["url"] as? String
            )
        )
    }

    /// Collect interactive elements (buttons, links, fields) for context.
    private static func collectInteractiveElements(
        from element: Element,
        roles: Set<String>,
        results: inout [[String: String]],
        depth: Int,
        maxDepth: Int
    ) {
        guard depth < maxDepth, results.count < 30 else { return }

        if let role = element.role(), roles.contains(role) {
            var info: [String: String] = ["role": role]
            if let name = element.computedName() { info["name"] = name }
            else if let title = element.title() { info["name"] = title }
            if info["name"] != nil {
                results.append(info)
            }
        }

        guard let children = element.children() else { return }
        for child in children {
            collectInteractiveElements(from: child, roles: roles, results: &results, depth: depth + 1, maxDepth: maxDepth)
        }
    }
}
