// ClickHandler.swift - Click action logic extracted from Actions.swift
//
// Dual-strategy approach: AX-native first, synthetic fallback.

import AppKit
import AXorcist
import Foundation

/// Handles daemon_click: AX-native press first, synthetic position-based fallback.
enum ClickHandler {

    /// Click an element. AX-native first via AXorcist's PerformAction command,
    /// synthetic fallback with position-based click.
    static func click(
        query: String?,
        role: String?,
        domId: String?,
        appName: String?,
        x: Double?,
        y: Double?,
        button: String?,
        count: Int?
    ) -> ToolResult {
        let mouseButton: MouseButton = switch button {
        case "right": .right
        case "middle": .middle
        default: .left
        }
        let clickCount = max(1, count ?? 1)

        // Coordinate-based click (no element lookup)
        if let x, let y {
            if let appName {
                _ = FocusManager.focus(appName: appName)
                Thread.sleep(forTimeInterval: 0.2)
            }
            do {
                try InputDriver.click(at: CGPoint(x: x, y: y), button: mouseButton, count: clickCount)
                Thread.sleep(forTimeInterval: 0.15)
                return ToolResult(
                    success: true,
                    data: ["method": "coordinate", "x": x, "y": y]
                )
            } catch {
                return ToolResult(success: false, error: "Click at (\(Int(x)), \(Int(y))) failed: \(error)")
            }
        }

        // Element-based click needs query or domId
        guard query != nil || domId != nil else {
            return ToolResult(
                success: false,
                error: "Either query/dom_id or x/y coordinates required",
                suggestion: "Use daemon_find to locate elements, or daemon_element_at for coordinates"
            )
        }

        // Build locator for AXorcist
        let locator = LocatorBuilder.build(query: query, role: role, domId: domId)

        // Strategy 1: AX-native via AXorcist's PerformAction command
        if mouseButton == .left && clickCount == 1 {
            let actionCmd = PerformActionCommand(
                appIdentifier: appName,
                locator: locator,
                action: "AXPress",
                maxDepthForSearch: DaemonConstants.semanticDepthBudget
            )
            let response = AXorcist.shared.runCommand(
                AXCommandEnvelope(commandID: "click", command: .performAction(actionCmd))
            )

            switch response {
            case .success:
                usleep(300_000)
                Log.info("AX-native press succeeded for '\(query ?? domId ?? "")'")
                return ToolResult(
                    success: true,
                    data: [
                        "method": "ax-native",
                        "element": query ?? domId ?? "",
                    ]
                )
            case let .error(message, code, _):
                Log.info("AX-native press failed for '\(query ?? domId ?? "")': [\(code)] \(message) - trying synthetic")
            }
        }

        // Strategy 2: Find element position, synthetic click
        guard let element = ActionHelpers.findElement(locator: locator, appName: appName) else {
            return ToolResult(
                success: false,
                error: "Element '\(query ?? domId ?? "")' not found in \(appName ?? "frontmost app")",
                suggestion: "Use daemon_find to see what elements are available"
            )
        }

        // Pre-flight: check actionable
        if !element.isActionable() {
            return ToolResult(
                success: false,
                error: "Element '\(element.computedName() ?? query ?? "")' is not actionable",
                suggestion: "Element may be disabled, hidden, or off-screen. Use daemon_inspect to check."
            )
        }

        // Focus the app for synthetic input
        if let appName {
            _ = FocusManager.focus(appName: appName)
            Thread.sleep(forTimeInterval: 0.2)
        }

        do {
            try element.click(button: mouseButton, clickCount: clickCount)
            Thread.sleep(forTimeInterval: 0.15)
            return ToolResult(
                success: true,
                data: [
                    "method": "synthetic",
                    "element": element.computedName() ?? query ?? "",
                ]
            )
        } catch {
            return ToolResult(
                success: false,
                error: "Click failed: \(error)",
                suggestion: "Try daemon_inspect on the element, or use x/y coordinates"
            )
        }
    }
}
