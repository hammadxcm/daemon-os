// ContentLengthTransport.swift - Content-Length framed MCP transport

import Foundation

/// Content-Length framed transport: Content-Length: N\r\n\r\n{json}
public final class ContentLengthTransport: MCPTransport {
    private let input: FileHandle
    private let output: FileHandle

    public init(input: FileHandle = .standardInput, output: FileHandle) {
        self.input = input
        self.output = output
    }

    public func readMessage() -> [String: Any]? {
        var header = ""

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

    public func writeMessage(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message) else {
            Log.error("Failed to serialize response")
            return
        }
        let header = "Content-Length: \(data.count)\r\n\r\n"
        output.write(Data(header.utf8))
        output.write(data)
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
