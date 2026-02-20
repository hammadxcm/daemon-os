// FailurePolicyTests.swift - Unit tests for FailurePolicy enum

import Foundation
import Testing
@testable import DaemonOS

@Suite("FailurePolicy Tests")
struct FailurePolicyTests {

    @Test("stop and skip cases exist")
    func casesExist() {
        let stop = FailurePolicy.stop
        let skip = FailurePolicy.skip
        #expect(stop == .stop)
        #expect(skip == .skip)
    }

    @Test("rawValue round-trip for stop")
    func rawValueRoundTripStop() {
        #expect(FailurePolicy.stop.rawValue == "stop")
        #expect(FailurePolicy(rawValue: "stop") == .stop)
    }

    @Test("rawValue round-trip for skip")
    func rawValueRoundTripSkip() {
        #expect(FailurePolicy.skip.rawValue == "skip")
        #expect(FailurePolicy(rawValue: "skip") == .skip)
    }

    @Test("Invalid rawValue returns nil")
    func invalidRawValueReturnsNil() {
        #expect(FailurePolicy(rawValue: "abort") == nil)
        #expect(FailurePolicy(rawValue: "") == nil)
        #expect(FailurePolicy(rawValue: "Stop") == nil) // case-sensitive
    }

    @Test("Codable round-trip for stop")
    func codableRoundTripStop() throws {
        let data = try JSONEncoder().encode(FailurePolicy.stop)
        let decoded = try JSONDecoder().decode(FailurePolicy.self, from: data)
        #expect(decoded == .stop)
    }

    @Test("Codable round-trip for skip")
    func codableRoundTripSkip() throws {
        let data = try JSONEncoder().encode(FailurePolicy.skip)
        let decoded = try JSONDecoder().decode(FailurePolicy.self, from: data)
        #expect(decoded == .skip)
    }

    @Test("Codable decodes from raw JSON string")
    func codableFromRawJSON() throws {
        let stopJSON = Data("\"stop\"".utf8)
        let skipJSON = Data("\"skip\"".utf8)
        let decodedStop = try JSONDecoder().decode(FailurePolicy.self, from: stopJSON)
        let decodedSkip = try JSONDecoder().decode(FailurePolicy.self, from: skipJSON)
        #expect(decodedStop == .stop)
        #expect(decodedSkip == .skip)
    }
}
