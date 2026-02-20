// ScrollHandler.swift - Scroll logic extracted from Actions.swift
//
// Handles daemon_scroll with element-based and coordinate-based strategies.

import AXorcist
import Foundation

/// Handles daemon_scroll: element-based scroll for apps, coordinate-based fallback.
enum ScrollHandler {

    // MARK: - daemon_scroll

    /// Scroll in a direction. Uses AXorcist's element-based scroll when app is
    /// specified (auto-handles multi-monitor via AX coordinates). Falls back to
    /// InputDriver.scroll with explicit coordinates when x,y are provided.
    static func scroll(
        direction: String,
        amount: Int?,
        appName: String?,
        x: Double?,
        y: Double?
    ) -> ToolResult {
        let scrollAmount = amount ?? 3

        guard let scrollDir = mapScrollDirection(direction) else {
            return ToolResult(success: false, error: "Invalid direction: '\(direction)'")
        }

        // If explicit coordinates provided, use InputDriver directly
        if let x, let y {
            if let appName {
                _ = FocusManager.focus(appName: appName)
                Thread.sleep(forTimeInterval: 0.2)
            }
            do {
                try Element.scrollAt(
                    CGPoint(x: x, y: y),
                    direction: scrollDir,
                    amount: scrollAmount
                )
                return ToolResult(success: true, data: ["direction": direction, "amount": scrollAmount])
            } catch {
                return ToolResult(success: false, error: "Scroll failed: \(error)")
            }
        }

        // If app specified, use element-based scroll on the focused window.
        if let appName {
            guard let appElement = AppResolver.appElement(for: appName) else {
                return ToolResult(success: false, error: "Application '\(appName)' not found")
            }
            guard let window = appElement.focusedWindow() ?? appElement.mainWindow() else {
                return ToolResult(success: false, error: "No window found for '\(appName)'")
            }

            // Find a scrollable area within the window
            let scrollTarget = findScrollable(in: window) ?? window

            do {
                try scrollTarget.scroll(direction: scrollDir, amount: scrollAmount)
                return ToolResult(success: true, data: ["direction": direction, "amount": scrollAmount])
            } catch {
                // Fallback: try scrolling at the window's center
                if let frame = window.frame() {
                    let center = CGPoint(x: frame.midX, y: frame.midY)
                    do {
                        try Element.scrollAt(center, direction: scrollDir, amount: scrollAmount)
                        return ToolResult(success: true, data: ["direction": direction, "amount": scrollAmount])
                    } catch {
                        return ToolResult(success: false, error: "Scroll failed: \(error)")
                    }
                }
                return ToolResult(success: false, error: "Scroll failed: \(error)")
            }
        }

        // No app, no coordinates - scroll at current mouse position
        do {
            let lines = Double(scrollAmount)
            let deltaY: Double = (direction == "up" ? lines * 10 : -lines * 10)
            try InputDriver.scroll(deltaY: deltaY, at: nil)
            return ToolResult(success: true, data: ["direction": direction, "amount": scrollAmount])
        } catch {
            return ToolResult(success: false, error: "Scroll failed: \(error)")
        }
    }

    // MARK: - Helpers

    /// Find a scrollable element within a window (AXScrollArea or AXWebArea).
    private static func findScrollable(in element: Element, depth: Int = 0) -> Element? {
        guard depth < 5 else { return nil }
        let role = element.role() ?? ""
        if role == "AXScrollArea" || role == "AXWebArea" { return element }
        guard let children = element.children() else { return nil }
        for child in children {
            if let found = findScrollable(in: child, depth: depth + 1) {
                return found
            }
        }
        return nil
    }

    /// Map direction string to AXorcist's ScrollDirection enum.
    private static func mapScrollDirection(_ direction: String) -> ScrollDirection? {
        switch direction.lowercased() {
        case "up": .up
        case "down": .down
        case "left": .left
        case "right": .right
        default: nil
        }
    }
}
