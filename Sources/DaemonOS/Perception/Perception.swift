// Perception.swift - Facade for all perception functions
//
// Maps to MCP tools: daemon_context, daemon_state, daemon_find, daemon_read,
// daemon_inspect, daemon_element_at, daemon_screenshot
//
// This file is a thin facade. Logic is split into focused sub-modules:
//   ContextProvider   - buildContext, collectInteractiveElements
//   StateProvider     - buildAppInfo
//   ElementSearcher   - semanticDepthSearch, hasSemanticContent
//   ContentReader     - collectContent (semantic depth tunneling)
//   InspectorHelper   - elementSummary, fullElementInfo
//   ScreenshotCapture - captureScreenshotSync
//
// Shared helpers (findWebArea, readURL, readValue, readDOMId, etc.) live
// in Common/ElementFinder.swift and Common/AppResolver.swift.

import AppKit
import AXorcist
import Foundation

/// Perception module: reading the screen state for the agent.
public enum Perception {

    // MARK: - daemon_context

    /// Get orientation context: focused app, window, URL, focused element, visible interactive elements.
    public static func getContext(appName: String?) -> ToolResult {
        if let appName {
            guard let app = AppResolver.findApp(named: appName) else {
                return ToolResult(
                    success: false,
                    error: "Application '\(appName)' not found or not running",
                    suggestion: "Use daemon_state to see all running apps"
                )
            }
            return ContextProvider.buildContext(for: app)
        } else {
            guard let frontApp = NSWorkspace.shared.frontmostApplication else {
                return ToolResult(success: false, error: "No frontmost application found")
            }
            return ContextProvider.buildContext(for: frontApp)
        }
    }

    // MARK: - daemon_state

    /// Get all running apps and their windows.
    public static func getState(appName: String?) -> ToolResult {
        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular
        }

        if let appName {
            guard let app = apps.first(where: {
                $0.localizedName?.localizedCaseInsensitiveContains(appName) == true
            }) else {
                return ToolResult(
                    success: false,
                    error: "Application '\(appName)' not found",
                    suggestion: "Use daemon_state without app parameter to see all running apps"
                )
            }
            return ToolResult(success: true, data: ["apps": [StateProvider.buildAppInfo(app)]])
        }

        let appInfos = apps.compactMap { StateProvider.buildAppInfo($0) }
        return ToolResult(success: true, data: [
            "app_count": appInfos.count,
            "apps": appInfos,
        ])
    }

    // MARK: - daemon_find

    /// Find elements matching criteria in any app.
    public static func findElements(
        query: String?,
        role: String?,
        domId: String?,
        domClass: String?,
        identifier: String?,
        appName: String?,
        depth: Int?
    ) -> ToolResult {
        // Need at least one search criterion
        guard query != nil || role != nil || domId != nil || identifier != nil || domClass != nil else {
            return ToolResult(
                success: false,
                error: "At least one search parameter required (query, role, dom_id, identifier, or dom_class)",
                suggestion: "Use daemon_context to see what's on screen first"
            )
        }

        // Find the app element to search within
        let searchRoot: Element
        if let appName {
            guard let app = AppResolver.findApp(named: appName),
                  let appElement = Element.application(for: app.processIdentifier)
            else {
                return ToolResult(
                    success: false,
                    error: "Application '\(appName)' not found",
                    suggestion: "Use daemon_state to see all running apps"
                )
            }
            searchRoot = appElement
        } else {
            guard let frontApp = NSWorkspace.shared.frontmostApplication,
                  let appElement = Element.application(for: frontApp.processIdentifier)
            else {
                return ToolResult(success: false, error: "No frontmost application accessible")
            }
            searchRoot = appElement
        }

        let maxDepth = min(depth ?? DaemonConstants.semanticDepthBudget, DaemonConstants.maxSearchDepth)

        // Strategy 1: DOM ID (most precise, bypasses depth limits)
        if let domId {
            if let element = ElementFinder.findByDOMId(domId, in: searchRoot, maxDepth: maxDepth) {
                return ToolResult(success: true, data: ["elements": [InspectorHelper.elementSummary(element)], "count": 1])
            }
            return ToolResult(
                success: true,
                data: ["elements": [] as [Any], "count": 0],
                suggestion: "No element with DOM id '\(domId)' found. Try daemon_read to see what's on the page."
            )
        }

        // Strategy 2: AXorcist's search with ElementSearchOptions
        var options = ElementSearchOptions()
        options.maxDepth = maxDepth
        options.caseInsensitive = true
        if let role {
            options.includeRoles = [role]
        }

        var results: [Element] = []

        if let identifier {
            if let el = searchRoot.findElement(byIdentifier: identifier) {
                results = [el]
            }
        } else if let query {
            results = searchRoot.searchElements(matching: query, options: options)
        } else if let role {
            results = searchRoot.searchElements(byRole: role, options: options)
        }

        // Also try semantic-depth search if AXorcist search yields nothing
        if results.isEmpty, let query {
            results = ElementSearcher.semanticDepthSearch(query: query, role: role, in: searchRoot, maxDepth: maxDepth)
        }

        // Deduplicate by element identity (Chrome multiple windows cause duplicates)
        var seen = Set<Int>()
        var unique: [Element] = []
        for el in results {
            let hash = el.hashValue
            if seen.insert(hash).inserted {
                unique.append(el)
            }
        }

        // Cap results to avoid huge responses
        let capped = Array(unique.prefix(50))
        let summaries = capped.map { InspectorHelper.elementSummary($0) }

        return ToolResult(
            success: true,
            data: [
                "elements": summaries,
                "count": summaries.count,
                "total_matches": results.count,
            ]
        )
    }

    // MARK: - daemon_read

    /// Read text content from screen using semantic depth tunneling.
    public static func readContent(appName: String?, query: String?, depth: Int?) -> ToolResult {
        let searchRoot: Element
        if let appName {
            guard let app = AppResolver.findApp(named: appName),
                  let appElement = Element.application(for: app.processIdentifier)
            else {
                return ToolResult(success: false, error: "Application '\(appName)' not found")
            }
            searchRoot = appElement
        } else {
            guard let frontApp = NSWorkspace.shared.frontmostApplication,
                  let appElement = Element.application(for: frontApp.processIdentifier)
            else {
                return ToolResult(success: false, error: "No frontmost application accessible")
            }
            searchRoot = appElement
        }

        let maxDepth = depth ?? DaemonConstants.semanticDepthBudget

        // If query provided, narrow to that element first
        var readRoot = searchRoot
        if let query {
            var options = ElementSearchOptions()
            options.maxDepth = maxDepth
            if let found = searchRoot.findElement(matching: query, options: options) {
                readRoot = found
            }
        } else {
            // For web apps, start from AXWebArea for better depth reach
            if let window = searchRoot.focusedWindow(),
               let webArea = ElementFinder.findWebArea(in: window)
            {
                readRoot = webArea
            } else if let window = searchRoot.focusedWindow() {
                readRoot = window
            }
        }

        // Use semantic depth tunneling to extract content
        var items: [String] = []
        ContentReader.collectContent(from: readRoot, items: &items, semanticDepth: 0, maxSemanticDepth: maxDepth)

        return ToolResult(
            success: true,
            data: [
                "content": items.joined(separator: "\n"),
                "item_count": items.count,
            ]
        )
    }

    // MARK: - daemon_inspect

    /// Full metadata about one element.
    public static func inspect(
        query: String,
        role: String?,
        domId: String?,
        appName: String?
    ) -> ToolResult {
        let searchRoot: Element
        if let appName {
            guard let app = AppResolver.findApp(named: appName),
                  let appElement = Element.application(for: app.processIdentifier)
            else {
                return ToolResult(success: false, error: "Application '\(appName)' not found")
            }
            searchRoot = appElement
        } else {
            guard let frontApp = NSWorkspace.shared.frontmostApplication,
                  let appElement = Element.application(for: frontApp.processIdentifier)
            else {
                return ToolResult(success: false, error: "No frontmost application accessible")
            }
            searchRoot = appElement
        }

        // Find the element
        let element: Element?
        if let domId {
            element = ElementFinder.findByDOMId(domId, in: searchRoot, maxDepth: DaemonConstants.semanticDepthBudget)
        } else {
            var options = ElementSearchOptions()
            options.maxDepth = DaemonConstants.semanticDepthBudget
            if let role { options.includeRoles = [role] }
            element = searchRoot.findElement(matching: query, options: options)
        }

        guard let element else {
            return ToolResult(
                success: false,
                error: "Element '\(query)' not found",
                suggestion: "Try daemon_find to see what elements are available, or daemon_context for orientation"
            )
        }

        return ToolResult(success: true, data: InspectorHelper.fullElementInfo(element))
    }

    // MARK: - daemon_element_at

    /// Get element at screen coordinates.
    public static func elementAt(x: Double, y: Double) -> ToolResult {
        let point = CGPoint(x: x, y: y)

        guard let element = Element.elementAtPoint(point) else {
            return ToolResult(
                success: false,
                error: "No element found at (\(Int(x)), \(Int(y)))",
                suggestion: "Coordinates may be outside any window. Use daemon_state to see window positions."
            )
        }

        return ToolResult(success: true, data: InspectorHelper.fullElementInfo(element))
    }

    // MARK: - daemon_screenshot

    /// Take a screenshot of an app window.
    public static func screenshot(appName: String?, fullResolution: Bool) -> ToolResult {
        let targetApp: NSRunningApplication
        if let appName {
            guard let app = AppResolver.findApp(named: appName) else {
                return ToolResult(success: false, error: "Application '\(appName)' not found")
            }
            targetApp = app
        } else {
            guard let frontApp = NSWorkspace.shared.frontmostApplication else {
                return ToolResult(success: false, error: "No frontmost application")
            }
            targetApp = frontApp
        }

        // ScreenCaptureKit is async - bridge to sync with RunLoop spinning
        let pid = targetApp.processIdentifier
        let result = ScreenshotCapture.captureScreenshotSync(pid: pid, fullResolution: fullResolution)

        guard let result else {
            return ToolResult(
                success: false,
                error: "Screenshot capture failed",
                suggestion: "Ensure Screen Recording permission is granted in System Settings > Privacy & Security > Screen Recording"
            )
        }

        return ToolResult(
            success: true,
            data: [
                "image": result.base64PNG,
                "width": result.width,
                "height": result.height,
                "window_title": result.windowTitle as Any,
                "mime_type": result.mimeType,
            ]
        )
    }

    // MARK: - Compatibility Wrappers
    //
    // These delegate to AppResolver and ElementFinder from Common/.
    // Kept here because Actions.swift, WaitManager.swift, and other modules
    // call Perception.findApp, Perception.appElement, etc.

    /// Find a running app by name (case-insensitive, contains match).
    static func findApp(named name: String) -> NSRunningApplication? {
        AppResolver.findApp(named: name)
    }

    /// Get the app Element for a named app.
    static func appElement(for name: String) -> Element? {
        AppResolver.appElement(for: name)
    }

    /// Find AXWebArea element within a window (for reading URLs from browsers).
    static func findWebArea(in element: Element, depth: Int = 0) -> Element? {
        ElementFinder.findWebArea(in: element, depth: depth)
    }

    /// Read URL from an element.
    static func readURL(from element: Element) -> String? {
        ElementFinder.readURL(from: element)
    }

    /// Read element value, working around AXorcist's Chrome AXStaticText bug.
    static func readValue(from element: Element) -> String? {
        ElementFinder.readValue(from: element)
    }
}
