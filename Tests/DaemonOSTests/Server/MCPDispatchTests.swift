// MCPDispatchTests.swift - Unit tests for MCPDispatch routing and formatting

import Foundation
import Testing
@testable import DaemonOS

@Suite("MCPDispatch")
struct MCPDispatchTests {

    // MARK: - handle routing

    @Test("handle with missing tool name returns error")
    func handleMissingToolName() {
        let result = MCPDispatch.handle([:])
        let isError = result["isError"] as? Bool
        #expect(isError == true)
    }

    @Test("handle with empty params returns error")
    func handleEmptyParams() {
        let result = MCPDispatch.handle(["arguments": ["key": "value"]])
        let isError = result["isError"] as? Bool
        #expect(isError == true)
    }

    @Test("handle with unknown tool returns error")
    func handleUnknownTool() {
        let result = MCPDispatch.handle(["name": "nonexistent_tool"])
        let isError = result["isError"] as? Bool
        #expect(isError == true)
        // The content should mention the unknown tool
        let content = result["content"] as? [[String: Any]]
        let text = content?.first?["text"] as? String ?? ""
        #expect(text.contains("Unknown tool"))
    }

    @Test("handle result always contains content array")
    func handleResultShape() {
        let result = MCPDispatch.handle([:])
        let content = result["content"] as? [[String: Any]]
        #expect(content != nil)
        #expect(content?.isEmpty == false)
    }

    @Test("handle result content entries have type field")
    func handleContentHasType() {
        let result = MCPDispatch.handle(["name": "nonexistent_tool"])
        let content = result["content"] as? [[String: Any]]
        #expect(content != nil)
        for entry in content ?? [] {
            #expect(entry["type"] is String)
        }
    }

    // MARK: - errorContent

    @Test("errorContent returns proper shape")
    func errorContentShape() {
        let result = MCPDispatch.errorContent("test error")
        #expect(result["isError"] as? Bool == true)
        let content = result["content"] as? [[String: Any]]
        #expect(content?.count == 1)
        #expect(content?.first?["type"] as? String == "text")
    }

    @Test("errorContent embeds message in text field")
    func errorContentMessage() {
        let result = MCPDispatch.errorContent("something went wrong")
        let content = result["content"] as? [[String: Any]]
        let text = content?.first?["text"] as? String ?? ""
        #expect(text.contains("something went wrong"))
    }

    @Test("errorContent text is valid JSON with success false")
    func errorContentTextIsJSON() {
        let result = MCPDispatch.errorContent("bad input")
        let content = result["content"] as? [[String: Any]]
        let text = content?.first?["text"] as? String ?? ""
        if let data = text.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
            #expect(json["success"] as? Bool == false)
            #expect(json["error"] as? String == "bad input")
        } else {
            Issue.record("errorContent text is not valid JSON: \(text)")
        }
    }

    @Test("errorContent with empty string still has correct structure")
    func errorContentEmptyMessage() {
        let result = MCPDispatch.errorContent("")
        #expect(result["isError"] as? Bool == true)
        let content = result["content"] as? [[String: Any]]
        #expect(content?.count == 1)
    }
}
