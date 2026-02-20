// TypeHandler.swift - Type/text-input logic extracted from Actions.swift
//
// Handles daemon_type: AX-native setValue first, click-then-type fallback.
// Includes field finding with editable-role scoring.

import AppKit
import AXorcist
import Foundation

/// Handles daemon_type with field finding, setValue, and synthetic typing.
enum TypeHandler {

    // MARK: - Main Entry Point

    /// Type text into a field. Uses AXorcist's SetFocusedValue command for
    /// AX-native typing (focus + setValue), with synthetic typeText fallback.
    static func typeText(
        text: String,
        into: String?,
        domId: String?,
        appName: String?,
        clear: Bool
    ) -> ToolResult {
        // If target field specified, find it and type into it
        if let fieldName = into ?? domId {
            let element: Element?
            if let domId {
                let locator = LocatorBuilder.build(domId: domId)
                element = ActionHelpers.findElement(locator: locator, appName: appName)
            } else if let into {
                element = findEditableField(named: into, appName: appName)
            } else {
                element = nil
            }

            guard let element else {
                return ToolResult(
                    success: false,
                    error: "Field '\(fieldName)' not found",
                    suggestion: "Use daemon_find to see available fields, or daemon_context for orientation"
                )
            }

            // Strategy 1: AX-native setValue
            if element.isAttributeSettable(named: "AXValue") {
                _ = element.setValue(true, forAttribute: "AXFocused")
                Thread.sleep(forTimeInterval: 0.1)

                if clear {
                    _ = element.setValue("", forAttribute: "AXValue")
                    Thread.sleep(forTimeInterval: 0.05)
                }

                let setOk = element.setValue(text, forAttribute: "AXValue")
                if setOk {
                    usleep(150_000)

                    // Verify: read AXValue DIRECTLY via raw API on the SAME element.
                    var readBackRef: CFTypeRef?
                    let readBackOk = AXUIElementCopyAttributeValue(
                        element.underlyingElement,
                        "AXValue" as CFString,
                        &readBackRef
                    )
                    let readback: String?
                    if readBackOk == .success, let ref = readBackRef {
                        if let str = ref as? String, !str.isEmpty {
                            readback = str
                        } else if CFGetTypeID(ref) == CFStringGetTypeID() {
                            readback = (ref as! CFString) as String
                        } else {
                            readback = nil
                        }
                    } else {
                        readback = nil
                    }

                    // Check if first 10 chars match
                    let textPrefix = String(text.prefix(10))
                    if let readback, readback.contains(textPrefix) {
                        return ToolResult(
                            success: true,
                            data: [
                                "method": "ax-native-setValue",
                                "field": fieldName,
                                "typed": text,
                                "readback": String(readback.prefix(200)),
                            ]
                        )
                    }
                    Log.info("setValue for '\(fieldName)' readback doesn't match - falling back to click-then-type")
                }
            }

            // Strategy 2: Click the element to focus it, then type synthetically
            if let appName {
                _ = FocusManager.focus(appName: appName)
                Thread.sleep(forTimeInterval: 0.2)
            }

            // Click the element to put cursor in the field
            if element.isActionable() {
                do {
                    try element.click()
                    Thread.sleep(forTimeInterval: 0.15)
                } catch {
                    _ = element.setValue(true, forAttribute: "AXFocused")
                    Thread.sleep(forTimeInterval: 0.1)
                }
            } else {
                _ = element.setValue(true, forAttribute: "AXFocused")
                Thread.sleep(forTimeInterval: 0.1)
            }

            do {
                if clear {
                    try Element.performHotkey(keys: ["cmd", "a"])
                    Thread.sleep(forTimeInterval: 0.05)
                    try Element.typeKey(.delete)
                    Thread.sleep(forTimeInterval: 0.05)
                    FocusManager.clearModifierFlags()
                }
                try Element.typeText(text, delay: 0.01)
                Thread.sleep(forTimeInterval: 0.15)

                let readback = readbackFromElement(element)
                let textPrefix = String(text.prefix(10))
                let verified = readback.contains(textPrefix)
                return ToolResult(
                    success: true,
                    data: [
                        "method": "click-then-type",
                        "field": fieldName,
                        "typed": text,
                        "verified": verified,
                        "readback": readback,
                    ]
                )
            } catch {
                return ToolResult(success: false, error: "Type into '\(fieldName)' failed: \(error)")
            }
        }

        // No target field - type at current focus
        if let appName {
            _ = FocusManager.focus(appName: appName)
            Thread.sleep(forTimeInterval: 0.2)
        }

        do {
            if clear {
                try Element.performHotkey(keys: ["cmd", "a"])
                Thread.sleep(forTimeInterval: 0.05)
                try Element.typeKey(.delete)
                Thread.sleep(forTimeInterval: 0.05)
                FocusManager.clearModifierFlags()
            }
            try Element.typeText(text, delay: 0.01)
            Thread.sleep(forTimeInterval: 0.1)
            return ToolResult(
                success: true,
                data: ["method": "synthetic-at-focus", "typed": text]
            )
        } catch {
            return ToolResult(success: false, error: "Type failed: \(error)")
        }
    }

    // MARK: - Field Finding

    /// Editable/input roles that the 'into' parameter should match against.
    private static let editableRoles: Set<String> = [
        "AXTextField", "AXTextArea", "AXComboBox", "AXSearchField",
        "AXSecureTextField",
    ]

    /// Layout roles that cost zero semantic depth (tunneled through).
    private static let layoutRoles: Set<String> = [
        "AXGroup", "AXGenericElement", "AXSection", "AXDiv",
        "AXList", "AXLandmarkMain", "AXLandmarkNavigation",
        "AXLandmarkBanner", "AXLandmarkContentInfo",
    ]

    /// Find an editable field by name. Searches ALL matching elements and
    /// scores them, preferring editable roles and exact/prefix matches.
    static func findEditableField(named query: String, appName: String?) -> Element? {
        guard let appElement = AppResolver.resolve(appName: appName) else { return nil }

        let queryLower = query.lowercased()

        // Search from content root first (web area), then full tree
        let searchRoot: Element
        if let window = appElement.focusedWindow(),
           let webArea = ElementFinder.findWebArea(in: window)
        {
            searchRoot = webArea
        } else if let window = appElement.focusedWindow() {
            searchRoot = window
        } else {
            searchRoot = appElement
        }

        // Collect ALL matching elements with scores.
        var candidates: [(element: Element, score: Int)] = []
        scoreFieldCandidates(
            element: searchRoot,
            queryLower: queryLower,
            candidates: &candidates,
            semanticDepth: 0,
            maxSemanticDepth: DaemonConstants.semanticDepthBudget
        )

        return candidates.max(by: { $0.score < $1.score })?.element
    }

    /// Walk the tree scoring elements as field candidates.
    /// Uses SEMANTIC depth (empty layout containers cost 0) so we can
    /// reach Gmail compose fields at DOM depth 30+ within budget of 25.
    private static func scoreFieldCandidates(
        element: Element,
        queryLower: String,
        candidates: inout [(element: Element, score: Int)],
        semanticDepth: Int,
        maxSemanticDepth: Int
    ) {
        guard semanticDepth <= maxSemanticDepth, candidates.count < 100 else { return }

        let role = element.role() ?? ""
        let titleLower = (element.title() ?? "").lowercased()
        let descLower = (element.descriptionText() ?? "").lowercased()
        let nameLower = (element.computedName() ?? "").lowercased()

        // Semantic depth: empty layout containers cost 0
        let hasContent = !titleLower.isEmpty || !descLower.isEmpty || !nameLower.isEmpty
        let isTunnel = layoutRoles.contains(role) && !hasContent
        let childSemanticDepth = isTunnel ? semanticDepth : semanticDepth + 1

        // Score: does this element's name match the query?
        var score = 0

        if titleLower == queryLower || descLower == queryLower || nameLower == queryLower {
            score = 100
        } else if titleLower.hasPrefix(queryLower) || descLower.hasPrefix(queryLower) || nameLower.hasPrefix(queryLower) {
            score = 80
        } else if titleLower.contains(queryLower) || descLower.contains(queryLower) || nameLower.contains(queryLower) {
            score = 60
        }

        if score > 0 {
            // Bonus for editable/interactive roles
            if editableRoles.contains(role) {
                score += 50
            }

            // Bonus for being on-screen (visible)
            if let pos = element.position(), let size = element.size() {
                let onScreen = NSScreen.screens.contains { screen in
                    screen.frame.intersects(CGRect(origin: pos, size: size))
                }
                if onScreen && size.width > 1 && size.height > 1 {
                    score += 20
                }
            }

            if score >= 50 {
                candidates.append((element: element, score: score))
            }
        }

        guard let children = element.children() else { return }
        for child in children {
            scoreFieldCandidates(
                element: child, queryLower: queryLower,
                candidates: &candidates,
                semanticDepth: childSemanticDepth,
                maxSemanticDepth: maxSemanticDepth
            )
        }
    }

    // MARK: - Readback Verification

    /// Read the current value of an element for verification.
    static func readbackFromElement(_ element: Element) -> String {
        // Try raw AXValue (Chrome compatible)
        if let value = ElementFinder.readValue(from: element), !value.isEmpty {
            return value.count > 200 ? String(value.prefix(200)) + "..." : value
        }
        // Try title
        if let title = element.title(), !title.isEmpty {
            return title.count > 200 ? String(title.prefix(200)) + "..." : title
        }
        // Try computedName
        if let name = element.computedName(), !name.isEmpty {
            return name.count > 200 ? String(name.prefix(200)) + "..." : name
        }
        return "(verification unavailable for this field type)"
    }
}
