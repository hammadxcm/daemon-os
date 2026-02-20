// MCPServer.swift - MCP JSON-RPC server over stdio
//
// Speaks the Model Context Protocol over stdin/stdout.
// Auto-detects transport: Content-Length framing or NDJSON.
// stdout is captured at init for exclusive MCP use; all other output goes to stderr.

import ApplicationServices
import Foundation

/// MCP server that handles JSON-RPC messages over stdio.
/// @MainActor ensures CoreGraphics server connection is initialized on the
/// main thread. Without this, ScreenCaptureKit crashes with CGS_REQUIRE_INIT.
@MainActor
public final class MCPServer {

    /// Dedicated file handle for MCP protocol output (the real stdout).
    private let mcpOutput: FileHandle

    /// Agent instructions content (served via initialize).
    private let instructions: String

    /// Transport format detected from first message.
    private var transport: Transport = .unknown

    private enum Transport {
        case unknown
        case contentLength  // Content-Length: N\r\n\r\n{json}
        case ndjson         // {json}\n
    }

    public init() {
        // Save the real stdout fd for MCP protocol, then redirect stdout -> stderr.
        // This ensures print()/Swift.print()/any library output goes to stderr,
        // keeping the MCP protocol channel clean.
        let savedFD = dup(STDOUT_FILENO)
        dup2(STDERR_FILENO, STDOUT_FILENO)
        self.mcpOutput = FileHandle(fileDescriptor: savedFD, closeOnDealloc: true)
        self.instructions = Self.loadInstructions()
    }

    /// Run the MCP server. Blocks forever reading stdin, dispatching tool calls,
    /// and writing responses. Exits when stdin closes.
    public func run() {
        Log.info("Daemon OS v\(DaemonOS.version) MCP server starting")

        while let message = readMessage() {
            guard let method = message["method"] as? String else {
                if let id = message["id"] {
                    writeError(id: id, code: -32600, message: "Invalid request: missing method")
                }
                continue
            }

            let id = message["id"]
            let params = message["params"] as? [String: Any] ?? [:]

            switch method {
            case "initialize":
                if let id {
                    writeResponse(id: id, result: handleInitialize(params))
                }

            case "notifications/initialized":
                Log.info("Client initialized")

            case "tools/list":
                if let id {
                    writeResponse(id: id, result: ["tools": MCPTools.definitions()])
                }

            case "tools/call":
                if let id {
                    writeResponse(id: id, result: MCPDispatch.handle(params))
                }

            case "ping":
                if let id {
                    writeResponse(id: id, result: [:] as [String: Any])
                }

            default:
                if let id {
                    writeError(id: id, code: -32601, message: "Method not found: \(method)")
                }
            }
        }

        Log.info("stdin closed, shutting down")
    }

    // MARK: - MCP Handlers

    private func handleInitialize(_ params: [String: Any]) -> [String: Any] {
        [
            "protocolVersion": "2024-11-05",
            "capabilities": ["tools": [:] as [String: Any]],
            "serverInfo": ["name": DaemonOS.name, "version": DaemonOS.version],
            "instructions": instructions,
        ]
    }

    // MARK: - Message I/O

    /// Read one JSON-RPC message from stdin, auto-detecting transport on first call.
    private func readMessage() -> [String: Any]? {
        if transport == .unknown {
            guard let firstByte = readByte() else { return nil }
            if firstByte == UInt8(ascii: "C") {
                transport = .contentLength
                return readContentLengthMessage(afterFirstByte: firstByte)
            } else if firstByte == UInt8(ascii: "{") {
                transport = .ndjson
                return readNDJSONMessage(afterFirstByte: firstByte)
            } else {
                Log.error("Unknown transport: first byte = \(firstByte)")
                return nil
            }
        }

        switch transport {
        case .contentLength:
            return readContentLengthMessage(afterFirstByte: nil)
        case .ndjson:
            return readNDJSONMessage(afterFirstByte: nil)
        case .unknown:
            return nil
        }
    }

    private func readContentLengthMessage(afterFirstByte: UInt8?) -> [String: Any]? {
        var header = ""
        if let byte = afterFirstByte {
            header.append(Character(UnicodeScalar(byte)))
        }

        while true {
            guard let byte = readByte() else { return nil }
            header.append(Character(UnicodeScalar(byte)))
            if header.hasSuffix("\r\n\r\n") { break }
            if header.count > 256 {
                Log.error("Content-Length header too long")
                return nil
            }
        }

        guard let range = header.range(of: "Content-Length: "),
              let endRange = header.range(of: "\r\n", range: range.upperBound..<header.endIndex)
        else {
            Log.error("Malformed Content-Length header: \(header)")
            return nil
        }
        let lengthStr = String(header[range.upperBound..<endRange.lowerBound])
        guard let length = Int(lengthStr), length > 0 else {
            Log.error("Invalid content length: \(lengthStr)")
            return nil
        }

        var body = Data()
        body.reserveCapacity(length)
        while body.count < length {
            guard let byte = readByte() else { return nil }
            body.append(byte)
        }

        return parseJSON(body)
    }

    private func readNDJSONMessage(afterFirstByte: UInt8?) -> [String: Any]? {
        var line = Data()
        if let byte = afterFirstByte {
            line.append(byte)
        }

        while true {
            guard let byte = readByte() else { return nil }
            if byte == UInt8(ascii: "\n") { break }
            line.append(byte)
        }

        return parseJSON(line)
    }

    private func readByte() -> UInt8? {
        var byte: UInt8 = 0
        let bytesRead = read(STDIN_FILENO, &byte, 1)
        return bytesRead == 1 ? byte : nil
    }

    private func parseJSON(_ data: Data) -> [String: Any]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            Log.error("Failed to parse JSON: \(String(data: data, encoding: .utf8) ?? "<binary>")")
            return nil
        }
        return json
    }

    /// Write a JSON-RPC success response.
    private func writeResponse(id: Any, result: [String: Any]) {
        let response: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id,
            "result": result,
        ]
        writeMessage(response)
    }

    /// Write a JSON-RPC error response.
    private func writeError(id: Any, code: Int, message: String) {
        let response: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id,
            "error": ["code": code, "message": message],
        ]
        writeMessage(response)
    }

    /// Write a JSON-RPC message using the detected transport format.
    private func writeMessage(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message) else {
            Log.error("Failed to serialize response")
            return
        }

        switch transport {
        case .ndjson, .unknown:
            mcpOutput.write(data)
            mcpOutput.write(Data("\n".utf8))
        case .contentLength:
            let header = "Content-Length: \(data.count)\r\n\r\n"
            mcpOutput.write(Data(header.utf8))
            mcpOutput.write(data)
        }
    }

    // MARK: - Instructions

    private static func loadInstructions() -> String {
        // Try loading from DAEMON-MCP.md next to the binary
        let binaryPath = ProcessInfo.processInfo.arguments[0]
        let binaryDir = (binaryPath as NSString).deletingLastPathComponent
        let instructionsPath = (binaryDir as NSString).appendingPathComponent("DAEMON-MCP.md")

        if let content = try? String(contentsOfFile: instructionsPath, encoding: .utf8) {
            return content
        }

        // Fallback minimal instructions
        return """
        Daemon OS gives you eyes and hands on macOS. Call daemon_recipes first for multi-step tasks. \
        Call daemon_context before acting. Use daemon_find to locate elements. \
        Always pass the app parameter to action tools.
        """
    }
}
