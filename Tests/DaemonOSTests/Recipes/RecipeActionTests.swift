// RecipeActionTests.swift - Unit tests for RecipeAction enum

import Foundation
import Testing
@testable import DaemonOS

@Suite("RecipeAction Tests")
struct RecipeActionTests {

    @Test("All enum cases exist")
    func allCasesExist() {
        // Verify each case can be constructed
        let click = RecipeAction.click
        let type = RecipeAction.type
        let press = RecipeAction.press
        let hotkey = RecipeAction.hotkey
        let focus = RecipeAction.focus
        let scroll = RecipeAction.scroll
        let wait = RecipeAction.wait

        #expect(click == .click)
        #expect(type == .type)
        #expect(press == .press)
        #expect(hotkey == .hotkey)
        #expect(focus == .focus)
        #expect(scroll == .scroll)
        #expect(wait == .wait)
    }

    @Test("rawValue round-trip for each case")
    func rawValueRoundTrip() {
        let cases: [(RecipeAction, String)] = [
            (.click, "click"),
            (.type, "type"),
            (.press, "press"),
            (.hotkey, "hotkey"),
            (.focus, "focus"),
            (.scroll, "scroll"),
            (.wait, "wait"),
        ]
        for (action, expectedRawValue) in cases {
            #expect(action.rawValue == expectedRawValue)
            #expect(RecipeAction(rawValue: expectedRawValue) == action)
        }
    }

    @Test("CaseIterable count is 7")
    func caseIterableCount() {
        #expect(RecipeAction.allCases.count == 7)
    }

    @Test("Invalid rawValue returns nil")
    func invalidRawValueReturnsNil() {
        #expect(RecipeAction(rawValue: "invalid") == nil)
        #expect(RecipeAction(rawValue: "") == nil)
        #expect(RecipeAction(rawValue: "Click") == nil) // case-sensitive
    }

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        for action in RecipeAction.allCases {
            let data = try JSONEncoder().encode(action)
            let decoded = try JSONDecoder().decode(RecipeAction.self, from: data)
            #expect(decoded == action)
        }
    }
}
