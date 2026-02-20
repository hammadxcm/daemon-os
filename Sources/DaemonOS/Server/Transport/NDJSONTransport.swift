// NDJSONTransport.swift - Newline-delimited JSON MCP transport

import Foundation

/// NDJSON transport: {json}\n
public final class NDJSONTransport: MCPTransport {
    private let input: FileHandle
    private let output: FileHandle

    public init(input: FileHandle = .standardInput, output: FileHandle) {
        self.input = input
        self.output = output
    }

    public func readMessage() -> [String: Any]? {
        var line = Data()

        while true {
            guard let byte = readByte() else { return nil }
            if byte == UInt8(ascii: "\n") { break }
            line.append(byte)
        }

        return parseJSON(line)
    }

    public func writeMessage(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message) else {
            Log.error("Failed to serialize response")
            return
        }
        output.write(data)
        output.write(Data("\n".utf8))
    }

    private func readByte() -> UInt8? {
        var byte: UInt8 = 0
        let bytesRead = read(input.fileDescriptor, &byte, 1)
        return bytesRead == 1 ? byte : nil
    }

    private func parseJSON(_ data: Data) -> [String: Any]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            Log.error("Failed to parse JSON: \(String(data: data, encoding: .utf8) ?? "<binary>")")
            return nil
        }
        return json
    }
}
