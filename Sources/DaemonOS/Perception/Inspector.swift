// Inspector.swift - Element inspection for daemon_inspect and daemon_find
//
// Extracted from Perception.swift. Builds element summary and
// full metadata dictionaries.

import AXorcist
import Foundation

/// Builds element info dictionaries for daemon_inspect and daemon_find.
enum InspectorHelper {

    /// Build a concise summary of an element (for daemon_find results).
    static func elementSummary(_ element: Element) -> [String: Any] {
        var info: [String: Any] = [:]
        if let role = element.role() { info["role"] = role }
        if let name = element.computedName() { info["name"] = name }
        else if let title = element.title() { info["name"] = title }
        if let pos = element.position() { info["position"] = ["x": Int(pos.x), "y": Int(pos.y)] }
        if let size = element.size() { info["size"] = ["width": Int(size.width), "height": Int(size.height)] }
        info["actionable"] = element.isActionable()
        if let actions = element.supportedActions(), !actions.isEmpty {
            info["actions"] = actions
        }
        // Include DOM id if available (useful for web apps)
        if let domId = ElementFinder.readDOMId(from: element) {
            info["dom_id"] = domId
        }
        if let identifier = element.identifier() {
            info["identifier"] = identifier
        }
        return info
    }

    /// Build full metadata for an element (for daemon_inspect).
    static func fullElementInfo(_ element: Element) -> [String: Any] {
        var info: [String: Any] = [:]

        // Core identity
        if let role = element.role() { info["role"] = role }
        if let subrole = element.subrole() { info["subrole"] = subrole }
        if let title = element.title() { info["title"] = title }
        if let name = element.computedName() { info["computed_name"] = name }
        if let identifier = element.identifier() { info["identifier"] = identifier }
        if let desc = element.descriptionText() { info["description"] = desc }
        if let help = element.help() { info["help"] = help }

        // DOM attributes
        if let domId = ElementFinder.readDOMId(from: element) { info["dom_id"] = domId }
        if let domClasses = ElementFinder.readDOMClasses(from: element) { info["dom_classes"] = domClasses }

        // Geometry
        if let pos = element.position() { info["position"] = ["x": Int(pos.x), "y": Int(pos.y)] }
        if let size = element.size() { info["size"] = ["width": Int(size.width), "height": Int(size.height)] }
        if let frame = element.frame() {
            info["frame"] = ["x": Int(frame.origin.x), "y": Int(frame.origin.y),
                             "width": Int(frame.width), "height": Int(frame.height)]
        }

        // State
        info["actionable"] = element.isActionable()
        info["editable"] = element.isEditable()
        if let enabled = element.isEnabled() { info["enabled"] = enabled }
        if let focused = element.isFocused() { info["focused"] = focused }
        if let hidden = element.isHidden() { info["hidden"] = hidden }
        if let busy = element.isElementBusy() { info["busy"] = busy }
        if let modal = element.isModal() { info["modal"] = modal }

        // Actions
        if let actions = element.supportedActions(), !actions.isEmpty {
            info["supported_actions"] = actions
        }

        // Value / text - skip entirely for AXTextArea (terminal scrollback can be 100K+)
        // For other roles, truncate to 500 chars max
        let elementRole = element.role() ?? ""
        if elementRole != "AXTextArea" {
            if let value = ElementFinder.readValue(from: element) {
                if value.count > 500 {
                    info["value"] = String(value.prefix(500)) + "..."
                    info["value_length"] = value.count
                } else {
                    info["value"] = value
                }
            }
        } else {
            // For text areas, just report the length
            if let numChars = element.numberOfCharacters() {
                info["value_length"] = numChars
                info["value"] = "(text area with \(numChars) characters - use daemon_read to extract content)"
            }
        }
        if let selectedText = element.selectedText() {
            info["selected_text"] = selectedText.count > 200 ? String(selectedText.prefix(200)) + "..." : selectedText
        }
        if let placeholder = element.placeholderValue() { info["placeholder"] = placeholder }

        // Children count
        if let children = element.children() {
            info["child_count"] = children.count
        }

        // Parent role
        if let parent = element.parent(), let parentRole = parent.role() {
            info["parent_role"] = parentRole
        }

        return info
    }
}
