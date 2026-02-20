// WaitConditionTypeTests.swift - Unit tests for WaitConditionType enum

import Foundation
import Testing
@testable import DaemonOS

@Suite("WaitConditionType Tests")
struct WaitConditionTypeTests {

    @Test("All 7 cases exist")
    func allCasesExist() {
        let urlContains = WaitConditionType.urlContains
        let titleContains = WaitConditionType.titleContains
        let elementExists = WaitConditionType.elementExists
        let elementGone = WaitConditionType.elementGone
        let urlChanged = WaitConditionType.urlChanged
        let titleChanged = WaitConditionType.titleChanged
        let delay = WaitConditionType.delay

        #expect(urlContains == .urlContains)
        #expect(titleContains == .titleContains)
        #expect(elementExists == .elementExists)
        #expect(elementGone == .elementGone)
        #expect(urlChanged == .urlChanged)
        #expect(titleChanged == .titleChanged)
        #expect(delay == .delay)
    }

    @Test("rawValue matches expected strings")
    func rawValueStrings() {
        #expect(WaitConditionType.urlContains.rawValue == "urlContains")
        #expect(WaitConditionType.titleContains.rawValue == "titleContains")
        #expect(WaitConditionType.elementExists.rawValue == "elementExists")
        #expect(WaitConditionType.elementGone.rawValue == "elementGone")
        #expect(WaitConditionType.urlChanged.rawValue == "urlChanged")
        #expect(WaitConditionType.titleChanged.rawValue == "titleChanged")
        #expect(WaitConditionType.delay.rawValue == "delay")
    }

    @Test("CaseIterable count is 7")
    func caseIterableCount() {
        #expect(WaitConditionType.allCases.count == 7)
    }

    @Test("rawValue round-trip for all cases")
    func rawValueRoundTrip() {
        for conditionType in WaitConditionType.allCases {
            let rawValue = conditionType.rawValue
            let reconstructed = WaitConditionType(rawValue: rawValue)
            #expect(reconstructed == conditionType)
        }
    }

    @Test("Codable round-trip for all cases")
    func codableRoundTrip() throws {
        for conditionType in WaitConditionType.allCases {
            let data = try JSONEncoder().encode(conditionType)
            let decoded = try JSONDecoder().decode(WaitConditionType.self, from: data)
            #expect(decoded == conditionType)
        }
    }

    @Test("Invalid rawValue returns nil")
    func invalidRawValueReturnsNil() {
        #expect(WaitConditionType(rawValue: "invalid") == nil)
        #expect(WaitConditionType(rawValue: "url_contains") == nil) // not snake_case
        #expect(WaitConditionType(rawValue: "") == nil)
    }

    @Test("Codable decodes from raw JSON string")
    func codableFromRawJSON() throws {
        let json = Data("\"elementExists\"".utf8)
        let decoded = try JSONDecoder().decode(WaitConditionType.self, from: json)
        #expect(decoded == .elementExists)
    }
}
