// Actions.swift - Facade for all action functions in Daemon OS
//
// Maps to MCP tools: daemon_click, daemon_type, daemon_press, daemon_hotkey,
// daemon_scroll, daemon_window
//
// Architecture: Thin facade that delegates to focused sub-modules:
//   ClickHandler   - daemon_click (AX-native + synthetic)
//   TypeHandler    - daemon_type (setValue + click-then-type)
//   KeyHandler     - daemon_press, daemon_hotkey
//   ScrollHandler  - daemon_scroll
//   WindowController - daemon_window
//   ActionHelpers  - shared element finding

import AXorcist
import Foundation

/// Actions module: operating apps for the agent.
/// Public API facade - delegates to focused handler enums.
public enum Actions {

    // MARK: - daemon_click

    /// Click an element. AX-native first via AXorcist's PerformAction command,
    /// synthetic fallback with position-based click.
    public static func click(
        query: String?,
        role: String?,
        domId: String?,
        appName: String?,
        x: Double?,
        y: Double?,
        button: String?,
        count: Int?
    ) -> ToolResult {
        ClickHandler.click(
            query: query, role: role, domId: domId, appName: appName,
            x: x, y: y, button: button, count: count
        )
    }

    // MARK: - daemon_type

    /// Type text into a field. AX-native setValue first, synthetic fallback.
    public static func typeText(
        text: String,
        into: String?,
        domId: String?,
        appName: String?,
        clear: Bool
    ) -> ToolResult {
        TypeHandler.typeText(
            text: text, into: into, domId: domId, appName: appName, clear: clear
        )
    }

    // MARK: - daemon_press

    /// Press a single key with optional modifiers.
    public static func pressKey(
        key: String,
        modifiers: [String]?,
        appName: String?
    ) -> ToolResult {
        KeyHandler.pressKey(key: key, modifiers: modifiers, appName: appName)
    }

    // MARK: - daemon_hotkey

    /// Press a key combination. Clears modifier flags after to prevent stuck keys.
    public static func hotkey(
        keys: [String],
        appName: String?
    ) -> ToolResult {
        KeyHandler.hotkey(keys: keys, appName: appName)
    }

    // MARK: - daemon_scroll

    /// Scroll in a direction. Element-based for named apps, coordinate-based fallback.
    public static func scroll(
        direction: String,
        amount: Int?,
        appName: String?,
        x: Double?,
        y: Double?
    ) -> ToolResult {
        ScrollHandler.scroll(
            direction: direction, amount: amount, appName: appName, x: x, y: y
        )
    }

    // MARK: - daemon_window

    /// Window management operations.
    public static func manageWindow(
        action: String,
        appName: String,
        windowTitle: String?,
        x: Double?, y: Double?,
        width: Double?, height: Double?
    ) -> ToolResult {
        WindowController.manageWindow(
            action: action, appName: appName, windowTitle: windowTitle,
            x: x, y: y, width: width, height: height
        )
    }
}
