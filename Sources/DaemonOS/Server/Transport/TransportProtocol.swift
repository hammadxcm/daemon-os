// TransportProtocol.swift - MCP transport abstraction

import Foundation

/// Protocol for MCP message transport (Content-Length framing or NDJSON).
public protocol MCPTransport: Sendable {
    /// Read one JSON-RPC message. Returns nil on EOF.
    @MainActor func readMessage() -> [String: Any]?
    /// Write a JSON-RPC message.
    @MainActor func writeMessage(_ message: [String: Any])
}
