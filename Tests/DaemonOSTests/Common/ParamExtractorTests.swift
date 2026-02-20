// ParamExtractorTests.swift - Unit tests for ParamExtractor

import Testing
@testable import DaemonOS

@Suite("ParamExtractor")
struct ParamExtractorTests {

    // MARK: - String extraction

    @Test("string returns value when present")
    func stringPresent() {
        let extractor = ParamExtractor(["name": "Alice"])
        #expect(extractor.string("name") == "Alice")
    }

    @Test("string returns nil when key is missing")
    func stringMissing() {
        let extractor = ParamExtractor([:])
        #expect(extractor.string("name") == nil)
    }

    @Test("string returns nil when value is wrong type")
    func stringWrongType() {
        let extractor = ParamExtractor(["name": 42])
        #expect(extractor.string("name") == nil)
    }

    // MARK: - Int extraction

    @Test("int returns value when present as Int")
    func intFromInt() {
        let extractor = ParamExtractor(["count": 5])
        #expect(extractor.int("count") == 5)
    }

    @Test("int coerces Double to Int")
    func intFromDouble() {
        let extractor = ParamExtractor(["count": 3.7])
        #expect(extractor.int("count") == 3)
    }

    @Test("int returns nil when key is missing")
    func intMissing() {
        let extractor = ParamExtractor([:])
        #expect(extractor.int("count") == nil)
    }

    // MARK: - Double extraction

    @Test("double returns value when present as Double")
    func doubleFromDouble() {
        let extractor = ParamExtractor(["rate": 2.5])
        #expect(extractor.double("rate") == 2.5)
    }

    @Test("double coerces Int to Double")
    func doubleFromInt() {
        let extractor = ParamExtractor(["rate": 7])
        #expect(extractor.double("rate") == 7.0)
    }

    @Test("double returns nil when key is missing")
    func doubleMissing() {
        let extractor = ParamExtractor([:])
        #expect(extractor.double("rate") == nil)
    }

    // MARK: - Bool extraction

    @Test("bool returns value when present")
    func boolPresent() {
        let extractor = ParamExtractor(["flag": true])
        #expect(extractor.bool("flag") == true)
    }

    @Test("bool returns nil when key is missing")
    func boolMissing() {
        let extractor = ParamExtractor([:])
        #expect(extractor.bool("flag") == nil)
    }

    // MARK: - String array extraction

    @Test("stringArray returns value when present")
    func stringArrayPresent() {
        let extractor = ParamExtractor(["tags": ["a", "b", "c"]])
        #expect(extractor.stringArray("tags") == ["a", "b", "c"])
    }

    @Test("stringArray returns nil when key is missing")
    func stringArrayMissing() {
        let extractor = ParamExtractor([:])
        #expect(extractor.stringArray("tags") == nil)
    }

    // MARK: - require()

    @Test("require returns value when string key is present")
    func requirePresent() {
        let extractor = ParamExtractor(["app": "Finder"])
        let result = extractor.require("app")
        #expect(result.value == "Finder")
        #expect(result.error == nil)
    }

    @Test("require returns error when key is missing")
    func requireMissing() {
        let extractor = ParamExtractor([:])
        let result = extractor.require("app")
        #expect(result.value == nil)
        #expect(result.error != nil)
        #expect(result.error?.success == false)
        #expect(result.error?.error?.contains("Missing required parameter") == true)
    }
}
