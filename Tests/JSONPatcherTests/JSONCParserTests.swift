@testable import JSONPatcher
import XCTest

final class JSONCParserTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    // https://github.com/microsoft/node-jsonc-parser/blob/main/src/test/json.test.ts
    func testParseLiterals() throws {
        try assertValidParse("true", "true")
        try assertValidParse("false", "false")
        try assertValidParse("null", "null")
        try assertValidParse("\"foo\"", "\"foo\"")
        try assertValidParse("9//comment", "9")
    }

    func testParseObjects() throws {
        try assertValidParse("{}", "{}")
        try assertValidParse(#"{ "foo": true }"#, #"{"foo":true}"#)
        try assertValidParse(#"{ "bar": 8, "xoo": "foo" }"#, #"{"bar":8,"xoo":"foo"}"#)
        try assertValidParse(#"{ "hello": [], "world": {} }"#, #"{"hello":[],"world":{}}"#)
        try assertValidParse(#"{ "a": false, "b": true, "c": [ 7.4 ] }"#, #"{"a":false,"b":true,"c":[7.4]}"#)
        try assertValidParse(#"{ "lineComment": "//", "blockComment": ["/*", "*/"], "brackets": [ ["{", "}"], ["[", "]"], ["(", ")"] ] }"#, #"{"lineComment":"//","blockComment":["/*","*/"],"brackets":[["{","}"],["[","]"],["(",")"]]}"#)
        try assertValidParse(#"{ "hello": [], "world": {} }"#, #"{"hello":[],"world":{}}"#)
        try assertValidParse(#"{ "hello": { "again": { "inside": 5 }, "world": 1 }}"#, #"{"hello":{"again":{"inside":5},"world":1}}"#)
        try assertValidParse(#"{ "foo": /*hello*/true }"#, #"{"foo":true}"#)
        try assertValidParse(#"{ "": true }"#, #"{"":true}"#)
    }

    func testParseArrays() throws {
        try assertValidParse("[]", "[]");
        try assertValidParse("[ [],  [ [] ]]", "[[],[[]]]");
        try assertValidParse("[ 1, 2, 3 ]", "[1,2,3]");
        try assertValidParse(#"[ { "a": null } ]"#, #"[{"a":null}]"#);
    }

    private func assertValidParse(_ jsoncString: String, _ expected: String,
                             in file: StaticString = #file,
                             line: UInt = #line) throws {
        let value = try JSONCParser(jsoncString: jsoncString).parse()
        XCTAssertEqual(value.encode(), expected, file: file, line: line)
    }
}
