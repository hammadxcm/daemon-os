// ElementSearcher.swift - Semantic depth search for daemon_find
//
// Extracted from Perception.swift. Implements semantic depth tunneling:
// empty layout containers (AXGroup with no content) are traversed at
// zero depth cost, allowing deep search into web app DOM trees.

import AXorcist
import Foundation

/// Semantic depth search that tunnels through empty layout containers.
enum ElementSearcher {

    /// Search with semantic depth tunneling (finds elements AXorcist's flat search misses).
    static func semanticDepthSearch(
        query: String,
        role: String?,
        in root: Element,
        maxDepth: Int
    ) -> [Element] {
        var results: [Element] = []
        semanticSearchWalk(
            element: root, query: query.lowercased(), role: role,
            results: &results, semanticDepth: 0, maxDepth: maxDepth
        )
        return results
    }

    /// Check if an element has semantic content (vs. empty layout container).
    /// Layout containers with no text content are tunneled through at zero depth cost.
    static func hasSemanticContent(_ element: Element) -> Bool {
        let role = element.role() ?? ""
        // Empty layout containers tunnel through at zero cost
        let layoutRoles: Set<String> = [
            "AXGroup", "AXGenericElement", "AXSection", "AXDiv",
            "AXList", "AXLandmarkMain", "AXLandmarkNavigation",
            "AXLandmarkBanner", "AXLandmarkContentInfo",
        ]
        if layoutRoles.contains(role) {
            // Only costs depth if it has actual text content
            if element.title() != nil { return true }
            if ElementFinder.readValue(from: element) != nil { return true }
            if element.descriptionText() != nil { return true }
            return false
        }
        return true
    }

    // MARK: - Private

    private static func semanticSearchWalk(
        element: Element,
        query: String,
        role: String?,
        results: inout [Element],
        semanticDepth: Int,
        maxDepth: Int
    ) {
        guard semanticDepth <= maxDepth, results.count < 50 else { return }

        let hasContent = hasSemanticContent(element)
        let currentDepth = hasContent ? semanticDepth + 1 : semanticDepth

        // Check if this element matches
        if let role, element.role() != role {
            // Role doesn't match, skip this element but keep searching children
        } else {
            let name = element.computedName()?.lowercased() ?? ""
            let title = element.title()?.lowercased() ?? ""
            let value = ElementFinder.readValue(from: element)?.lowercased() ?? ""
            let desc = element.descriptionText()?.lowercased() ?? ""
            let identifier = element.identifier()?.lowercased() ?? ""

            if name.contains(query) || title.contains(query) || value.contains(query)
                || desc.contains(query) || identifier.contains(query)
            {
                results.append(element)
            }
        }

        guard let children = element.children() else { return }
        for child in children {
            semanticSearchWalk(
                element: child, query: query, role: role,
                results: &results, semanticDepth: currentDepth, maxDepth: maxDepth
            )
        }
    }
}
