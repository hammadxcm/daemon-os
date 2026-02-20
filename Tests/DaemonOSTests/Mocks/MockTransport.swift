// MockTransport.swift - In-memory MCP transport for testing

import Foundation
@testable import DaemonOS

/// In-memory transport that records sent messages and provides scripted responses.
final class MockTransport: MCPTransport, @unchecked Sendable {
    var incomingMessages: [[String: Any]] = []
    var sentMessages: [[String: Any]] = []
    private var readIndex = 0

    func readMessage() -> [String: Any]? {
        guard readIndex < incomingMessages.count else { return nil }
        let message = incomingMessages[readIndex]
        readIndex += 1
        return message
    }

    func writeMessage(_ message: [String: Any]) {
        sentMessages.append(message)
    }

    /// Queue a message to be read.
    func enqueue(_ message: [String: Any]) {
        incomingMessages.append(message)
    }

    /// Reset all state.
    func reset() {
        incomingMessages.removeAll()
        sentMessages.removeAll()
        readIndex = 0
    }
}
