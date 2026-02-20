// MCPServerTests.swift - Unit tests for MCPTools definitions

import Foundation
import Testing
@testable import DaemonOS

@Suite("MCPServer")
struct MCPServerTests {

    @Test("MCPTools defines exactly 20 tools")
    func toolCount() {
        let tools = MCPTools.definitions()
        #expect(tools.count == 20)
    }

    @Test("All tool names start with daemon_")
    func toolNamesPrefix() {
        let tools = MCPTools.definitions()
        for tool in tools {
            let name = tool["name"] as? String ?? ""
            #expect(name.hasPrefix("daemon_"), "Tool '\(name)' should start with daemon_")
        }
    }

    @Test("Each tool has required MCP fields")
    func toolStructure() {
        let tools = MCPTools.definitions()
        for tool in tools {
            #expect(tool["name"] is String)
            #expect(tool["description"] is String)
            #expect(tool["inputSchema"] is [String: Any])
        }
    }

    @Test("Tool names are unique")
    func toolNamesUnique() {
        let tools = MCPTools.definitions()
        let names = tools.compactMap { $0["name"] as? String }
        let uniqueNames = Set(names)
        #expect(names.count == uniqueNames.count, "Duplicate tool names found")
    }

    @Test("inputSchema always has type object")
    func inputSchemaType() {
        let tools = MCPTools.definitions()
        for tool in tools {
            let schema = tool["inputSchema"] as? [String: Any]
            #expect(schema?["type"] as? String == "object")
        }
    }

    @Test("No tool description is empty")
    func noEmptyDescriptions() {
        let tools = MCPTools.definitions()
        for tool in tools {
            let description = tool["description"] as? String ?? ""
            #expect(!description.isEmpty, "Tool \(tool["name"] ?? "?") has empty description")
        }
    }
}
