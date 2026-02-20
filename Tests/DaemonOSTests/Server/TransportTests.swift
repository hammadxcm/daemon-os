// TransportTests.swift - Unit tests for ContentLengthTransport and NDJSONTransport

import Foundation
import Testing
@testable import DaemonOS

@Suite("ContentLengthTransport")
struct ContentLengthTransportTests {

    @Test("writeMessage produces Content-Length framed output")
    func writeMessageFraming() {
        let pipe = Pipe()
        let transport = ContentLengthTransport(output: pipe.fileHandleForWriting)

        let message: [String: Any] = ["jsonrpc": "2.0", "method": "ping"]
        transport.writeMessage(message)
        pipe.fileHandleForWriting.closeFile()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let raw = String(data: data, encoding: .utf8) ?? ""

        #expect(raw.contains("Content-Length: "))
        #expect(raw.contains("\r\n\r\n"))

        // Extract body after the header separator
        if let range = raw.range(of: "\r\n\r\n") {
            let body = String(raw[range.upperBound...])
            let parsed = try? JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any]
            #expect(parsed?["method"] as? String == "ping")
        } else {
            Issue.record("Missing CRLFCRLF separator in Content-Length output")
        }
    }

    @Test("writeMessage and readMessage round-trip")
    func roundTrip() {
        let pipe = Pipe()
        let writer = ContentLengthTransport(output: pipe.fileHandleForWriting)
        let reader = ContentLengthTransport(
            input: pipe.fileHandleForReading,
            output: pipe.fileHandleForWriting
        )

        let message: [String: Any] = ["id": 1, "method": "tools/list"]
        writer.writeMessage(message)
        pipe.fileHandleForWriting.closeFile()

        let result = reader.readMessage()
        #expect(result != nil)
        #expect(result?["method"] as? String == "tools/list")
        #expect(result?["id"] as? Int == 1)
    }

    @Test("readMessage returns nil on empty input")
    func readEmptyInput() {
        let pipe = Pipe()
        pipe.fileHandleForWriting.closeFile()

        let transport = ContentLengthTransport(
            input: pipe.fileHandleForReading,
            output: pipe.fileHandleForWriting
        )
        let result = transport.readMessage()
        #expect(result == nil)
    }
}

@Suite("NDJSONTransport")
struct NDJSONTransportTests {

    @Test("writeMessage produces newline-delimited JSON")
    func writeMessageFormat() {
        let pipe = Pipe()
        let transport = NDJSONTransport(output: pipe.fileHandleForWriting)

        let message: [String: Any] = ["jsonrpc": "2.0", "method": "ping"]
        transport.writeMessage(message)
        pipe.fileHandleForWriting.closeFile()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let raw = String(data: data, encoding: .utf8) ?? ""

        #expect(raw.hasSuffix("\n"))
        // Body without trailing newline should be valid JSON
        let jsonStr = raw.trimmingCharacters(in: .newlines)
        let parsed = try? JSONSerialization.jsonObject(with: Data(jsonStr.utf8)) as? [String: Any]
        #expect(parsed?["method"] as? String == "ping")
    }

    @Test("writeMessage and readMessage round-trip")
    func roundTrip() {
        let pipe = Pipe()
        let writer = NDJSONTransport(output: pipe.fileHandleForWriting)
        let reader = NDJSONTransport(
            input: pipe.fileHandleForReading,
            output: pipe.fileHandleForWriting
        )

        let message: [String: Any] = ["id": 42, "method": "initialize"]
        writer.writeMessage(message)
        pipe.fileHandleForWriting.closeFile()

        let result = reader.readMessage()
        #expect(result != nil)
        #expect(result?["method"] as? String == "initialize")
        #expect(result?["id"] as? Int == 42)
    }

    @Test("readMessage returns nil on empty input")
    func readEmptyInput() {
        let pipe = Pipe()
        pipe.fileHandleForWriting.closeFile()

        let transport = NDJSONTransport(
            input: pipe.fileHandleForReading,
            output: pipe.fileHandleForWriting
        )
        let result = transport.readMessage()
        #expect(result == nil)
    }
}
