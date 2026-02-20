// AppResolverTests.swift - Unit tests for AppResolver

import Testing
@testable import DaemonOS

@Suite("AppResolver")
struct AppResolverTests {

    @Test("findApp returns nil for nonexistent app")
    func findNonexistent() {
        let result = AppResolver.findApp(named: "NonExistentAppXYZ99999")
        #expect(result == nil)
    }

    @Test("findApp finds Finder (always running)")
    func findFinder() {
        let result = AppResolver.findApp(named: "Finder")
        #expect(result != nil)
        #expect(result?.localizedName == "Finder")
    }

    @Test("findApp is case-insensitive")
    func caseInsensitive() {
        let result = AppResolver.findApp(named: "finder")
        #expect(result != nil)
    }

    @Test("appElement returns nil for nonexistent app")
    func appElementNonexistent() {
        let result = AppResolver.appElement(for: "NonExistentAppXYZ99999")
        #expect(result == nil)
    }

    @Test("appElement returns Element for Finder")
    func appElementFinder() {
        let result = AppResolver.appElement(for: "Finder")
        #expect(result != nil)
    }

    @Test("resolve with nil returns frontmost app element")
    func resolveNil() {
        let result = AppResolver.resolve(appName: nil)
        // Frontmost app should always exist in a desktop session
        #expect(result != nil)
    }

    @Test("resolve with valid name returns element")
    func resolveValidName() {
        let result = AppResolver.resolve(appName: "Finder")
        #expect(result != nil)
    }

    @Test("resolve with invalid name returns nil")
    func resolveInvalidName() {
        let result = AppResolver.resolve(appName: "NonExistentAppXYZ99999")
        #expect(result == nil)
    }
}
