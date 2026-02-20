// ActionHelpers.swift - Shared element-finding helpers for action handlers
//
// Uses AppResolver and ElementFinder from Common/ to avoid duplication.

import AXorcist
import Foundation

/// Shared element search helpers used by ClickHandler, TypeHandler, etc.
enum ActionHelpers {

    /// Find an element using content-root-first strategy with semantic depth.
    /// Searches AXWebArea first (in-page elements), then full app tree.
    static func findElement(locator: Locator, appName: String?) -> Element? {
        guard let appElement = AppResolver.resolve(appName: appName) else { return nil }

        // Content-root-first: search AXWebArea, then full tree
        if let window = appElement.focusedWindow(),
           let webArea = ElementFinder.findWebArea(in: window)
        {
            if let found = searchWithSemanticDepth(locator: locator, root: webArea) {
                return found
            }
        }

        // Full app tree fallback
        return searchWithSemanticDepth(locator: locator, root: appElement)
    }

    /// Search with semantic depth tunneling using AXorcist's Element.searchElements.
    /// Falls back to DOM ID search if AXorcist doesn't find it.
    static func searchWithSemanticDepth(locator: Locator, root: Element) -> Element? {
        // Try AXorcist's built-in search first
        if let query = locator.computedNameContains {
            var options = ElementSearchOptions()
            options.maxDepth = DaemonConstants.semanticDepthBudget
            if let roleCriteria = locator.criteria.first(where: { $0.attribute == "AXRole" }) {
                options.includeRoles = [roleCriteria.value]
            }
            if let found = root.findElement(matching: query, options: options) {
                return found
            }
        }

        // DOM ID search (bypasses depth limits) - delegate to Common/ElementFinder
        if let domIdCriteria = locator.criteria.first(where: { $0.attribute == "AXDOMIdentifier" }) {
            return ElementFinder.findByDOMId(domIdCriteria.value, in: root, maxDepth: 50)
        }

        return nil
    }
}
