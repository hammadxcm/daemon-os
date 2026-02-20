// KeyMappingTests.swift - Unit tests for KeyHandler.mapSpecialKey

import AXorcist
import Testing
@testable import DaemonOS

@Suite("Key Mapping")
struct KeyMappingTests {

    @Test("return maps to .return")
    func returnKey() {
        #expect(KeyHandler.mapSpecialKey("return") == .return)
    }

    @Test("enter maps to .return")
    func enterKey() {
        #expect(KeyHandler.mapSpecialKey("enter") == .return)
    }

    @Test("tab maps to .tab")
    func tabKey() {
        #expect(KeyHandler.mapSpecialKey("tab") == .tab)
    }

    @Test("escape maps to .escape")
    func escapeKey() {
        #expect(KeyHandler.mapSpecialKey("escape") == .escape)
    }

    @Test("esc maps to .escape")
    func escKey() {
        #expect(KeyHandler.mapSpecialKey("esc") == .escape)
    }

    @Test("space maps to .space")
    func spaceKey() {
        #expect(KeyHandler.mapSpecialKey("space") == .space)
    }

    @Test("delete maps to .delete")
    func deleteKey() {
        #expect(KeyHandler.mapSpecialKey("delete") == .delete)
    }

    @Test("backspace maps to .delete")
    func backspaceKey() {
        #expect(KeyHandler.mapSpecialKey("backspace") == .delete)
    }

    @Test("arrow keys map correctly")
    func arrowKeys() {
        #expect(KeyHandler.mapSpecialKey("up") == .up)
        #expect(KeyHandler.mapSpecialKey("down") == .down)
        #expect(KeyHandler.mapSpecialKey("left") == .left)
        #expect(KeyHandler.mapSpecialKey("right") == .right)
    }

    @Test("home and end keys")
    func homeEndKeys() {
        #expect(KeyHandler.mapSpecialKey("home") == .home)
        #expect(KeyHandler.mapSpecialKey("end") == .end)
    }

    @Test("page keys")
    func pageKeys() {
        #expect(KeyHandler.mapSpecialKey("pageup") == .pageUp)
        #expect(KeyHandler.mapSpecialKey("pagedown") == .pageDown)
    }

    @Test("function keys f1 through f12")
    func functionKeys() {
        #expect(KeyHandler.mapSpecialKey("f1") == .f1)
        #expect(KeyHandler.mapSpecialKey("f6") == .f6)
        #expect(KeyHandler.mapSpecialKey("f12") == .f12)
    }

    @Test("case insensitivity")
    func caseInsensitive() {
        #expect(KeyHandler.mapSpecialKey("RETURN") == .return)
        #expect(KeyHandler.mapSpecialKey("Tab") == .tab)
        #expect(KeyHandler.mapSpecialKey("ESCAPE") == .escape)
    }

    @Test("unknown key returns nil")
    func unknownKey() {
        #expect(KeyHandler.mapSpecialKey("foobar") == nil)
        #expect(KeyHandler.mapSpecialKey("") == nil)
        #expect(KeyHandler.mapSpecialKey("ctrl") == nil)
    }
}
