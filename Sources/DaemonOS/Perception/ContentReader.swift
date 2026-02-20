// ContentReader.swift - Content extraction for daemon_read
//
// Extracted from Perception.swift. Uses semantic depth tunneling
// to extract text content from the accessibility tree.

import AXorcist
import Foundation

/// Extracts text content using semantic depth tunneling.
enum ContentReader {

    /// Collect text content with semantic depth tunneling.
    /// Empty layout containers (AXGroup with no content) are traversed at zero depth cost.
    static func collectContent(
        from element: Element,
        items: inout [String],
        semanticDepth: Int,
        maxSemanticDepth: Int
    ) {
        guard semanticDepth <= maxSemanticDepth else { return }

        // Check if this element has meaningful content
        let hasContent = ElementSearcher.hasSemanticContent(element)
        let currentDepth = hasContent ? semanticDepth + 1 : semanticDepth

        // Extract text from this element
        if hasContent {
            var text = ""
            if element.role() != nil {
                // Read value, handling Chrome AXStaticText bug
                if let value = ElementFinder.readValue(from: element) {
                    text = value
                } else if let title = element.title() {
                    text = title
                } else if let name = element.computedName() {
                    text = name
                }
            }
            if !text.isEmpty {
                let role = element.role() ?? ""
                let prefix = role.hasPrefix("AXHeading") ? "# " :
                             role == "AXLink" ? "[link] " :
                             role == "AXButton" ? "[button] " : ""
                items.append("\(prefix)\(text)")
            }
        }

        // Recurse into children
        guard let children = element.children() else { return }
        for child in children {
            collectContent(from: child, items: &items, semanticDepth: currentDepth, maxSemanticDepth: maxSemanticDepth)
        }
    }
}
