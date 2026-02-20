// ElementFinder.swift - Shared element tree walking logic

import AXorcist
import Foundation

/// Deduplicated element search operations used across modules.
public enum ElementFinder {

    /// Find an element by DOM id, searching deep (ignoring depth budget for exact ID match).
    public static func findByDOMId(
        _ domId: String,
        in root: Element,
        maxDepth: Int = 50
    ) -> Element? {
        findByDOMIdWalk(element: root, domId: domId, depth: 0, maxDepth: maxDepth)
    }

    private static func findByDOMIdWalk(
        element: Element,
        domId: String,
        depth: Int,
        maxDepth: Int
    ) -> Element? {
        guard depth < maxDepth else { return nil }

        if let elDomId = element.rawAttributeValue(named: "AXDOMIdentifier") as? String,
           elDomId == domId
        {
            return element
        }

        guard let children = element.children() else { return nil }
        for child in children {
            if let found = findByDOMIdWalk(
                element: child, domId: domId, depth: depth + 1, maxDepth: maxDepth
            ) {
                return found
            }
        }
        return nil
    }

    /// Search for an element by computedName (not stringValue/text content).
    /// Used by WaitManager for elementExists/elementGone conditions.
    public static func findByComputedName(
        query: String,
        in element: Element,
        depth: Int = 0,
        maxDepth: Int = 15
    ) -> Bool {
        guard depth < maxDepth else { return false }

        let checkProps: [String?] = [
            element.title(),
            element.computedName(),
            element.descriptionText(),
            element.identifier(),
            readValue(from: element),
        ]
        for prop in checkProps {
            if let text = prop?.lowercased(), text.contains(query) {
                return true
            }
        }

        guard let children = element.children() else { return false }
        for child in children {
            if findByComputedName(query: query, in: child, depth: depth + 1, maxDepth: maxDepth) {
                return true
            }
        }
        return false
    }

    /// Read element value, working around AXorcist's Chrome AXStaticText bug.
    public static func readValue(from element: Element) -> String? {
        if let val = element.value() {
            if let str = val as? String, !str.isEmpty { return str }
        }
        if let cfValue = element.rawAttributeValue(named: "AXValue") {
            if let str = cfValue as? String, !str.isEmpty { return str }
            if CFGetTypeID(cfValue) == CFStringGetTypeID() {
                let str = (cfValue as! CFString) as String
                if !str.isEmpty { return str }
            }
        }
        return nil
    }

    /// Read DOM identifier from an element.
    public static func readDOMId(from element: Element) -> String? {
        if let cfValue = element.rawAttributeValue(named: "AXDOMIdentifier") {
            return cfValue as? String
        }
        return nil
    }

    /// Read DOM class list from an element.
    public static func readDOMClasses(from element: Element) -> String? {
        if let cfValue = element.rawAttributeValue(named: "AXDOMClassList") {
            if let str = cfValue as? String { return str }
            if let arr = cfValue as? [String] { return arr.joined(separator: " ") }
        }
        return nil
    }

    /// Find AXWebArea element within a window (for reading URLs from browsers).
    public static func findWebArea(in element: Element, depth: Int = 0) -> Element? {
        guard depth < 10 else { return nil }
        if element.role() == "AXWebArea" { return element }
        guard let children = element.children() else { return nil }
        for child in children {
            if let webArea = findWebArea(in: child, depth: depth + 1) {
                return webArea
            }
        }
        return nil
    }

    /// Read URL from an element.
    public static func readURL(from element: Element) -> String? {
        if let url = element.url() {
            return url.absoluteString
        }
        if let cfValue = element.rawAttributeValue(named: "AXURL") {
            if let url = cfValue as? URL { return url.absoluteString }
            if CFGetTypeID(cfValue) == CFURLGetTypeID() {
                return (cfValue as! CFURL as URL).absoluteString
            }
        }
        return nil
    }
}
