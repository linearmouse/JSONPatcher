@testable import JSONPatcher
import XCTest

final class JSONCScannerTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    // https://github.com/microsoft/node-jsonc-parser/blob/main/src/test/json.test.ts
    func testScanTokens() throws {
        try assertKinds("{", .leftBrace)
        try assertKinds("}", .rightBrace)
        try assertKinds("[", .leftBracket)
        try assertKinds("]", .rightBracket)
        try assertKinds(":", .colon)
        try assertKinds(",", .comma)
        try assertKinds(" {", .leftBrace)
    }

    func testScanComments() throws {
        try assertKinds("// this is a comment", .lineComment)
        try assertKinds("// this is a comment\n", .lineComment)
        try assertKinds("/* this is a comment*/", .blockComment)
        try assertKinds("/* this is a \r\ncomment*/", .blockComment)
        try assertKinds("/* this is a \ncomment*/", .blockComment)

        // unexpected end
        try assertThrowsParsingError("/* this is a") {
            guard case .unexpectedEOF(loc: _) = $0 else {
                return false
            }
            return true
        }
        try assertThrowsParsingError("/* this is a \ncomment") {
            guard case .unexpectedEOF(loc: _) = $0 else {
                return false
            }
            return true
        }

        // broken comment
        try assertThrowsParsingError("/ ttt") {
            guard case .invalidCommentStart(loc: _, character: " ") = $0 else {
                return false
            }
            return true
        }
    }

    func testScanStrings() throws {
        try assertKinds(#""test""#, .string)
        try assertKinds(#""\"""#, .string)
        try assertKinds(#""\/""#, .string)
        try assertKinds(#""\b""#, .string)
        try assertKinds(#""\f""#, .string)
        try assertKinds(#""\n""#, .string)
        try assertKinds(#""\r""#, .string)
        try assertKinds(#""\t""#, .string)
        try assertKinds(#""\u88ff""#, .string)
        try assertKinds(#""\u2028""#, .string)
        try assertThrowsParsingError(#""\v""#) {
            guard case .invalidEscapeCharacter(loc: _, character: "v") = $0 else {
                return false
            }
            return true
        }

        // unexpected end
        try assertThrowsParsingError(#""test"#) {
            guard case .unexpectedEOF(loc: _) = $0 else {
                return false
            }
            return true
        }
        try assertThrowsParsingError("\"test\n") {
            guard case .unexpectedEndOfString(loc: _) = $0 else {
                return false
            }
            return true
        }

        // invalid characters
        try assertThrowsParsingError("\"\t\"") {
            guard case .invalidCharacter(loc: _, character: "\t") = $0 else {
                return false
            }
            return true
        }
        try assertThrowsParsingError("\"\t \"") {
            guard case .invalidCharacter(loc: _, character: "\t") = $0 else {
                return false
            }
            return true
        }
        try assertThrowsParsingError("\"\0\"") {
            guard case .invalidCharacter(loc: _, character: "\0") = $0 else {
                return false
            }
            return true
        }
    }

    func testScanNumbers() throws {
        try assertKinds("0", .numeric)
        try assertKinds("0.1", .numeric)
        try assertKinds("0.0005", .numeric)
        try assertKinds("-0.1", .numeric)
        try assertKinds("-1", .numeric)
        try assertKinds("-0.0005", .numeric)
        try assertKinds("1", .numeric)
        try assertKinds("123456789", .numeric)
        try assertKinds("10", .numeric)
        try assertKinds("90", .numeric)
        try assertKinds("90E+123", .numeric)
        try assertKinds("90e+123", .numeric)
        try assertKinds("90e+00123", .numeric)
        try assertKinds("90e-123", .numeric)
        try assertKinds("90e-00123", .numeric)
        try assertKinds("90E-123", .numeric)
        try assertKinds("90E123", .numeric)
        try assertKinds("90e123", .numeric)

        // zero handling
        try assertKinds("01", .numeric, .numeric)
        try assertKinds("-01", .numeric, .numeric)

        // unexpected end
        try assertThrowsParsingError("-") {
            guard case .unexpectedEOF(loc: _) = $0 else {
                return false
            }
            return true
        }
        try assertThrowsParsingError(".0") {
            guard case .invalidCharacter(loc: _, character: ".") = $0 else {
                return false
            }
            return true
        }
    }

    func testScanKeywords() throws {
        try assertKinds("true", .true)
        try assertKinds("false", .false)
        try assertKinds("null", .null)
        try assertKinds("true false null", .true, .false, .null)

        // invalid words
        try assertThrowsParsingError("nulllll", .null) {
            guard case .invalidCharacter(loc: _, character: "l") = $0 else {
                return false
            }
            return true
        }
        try assertThrowsParsingError("True") {
            guard case .invalidCharacter(loc: _, character: "T") = $0 else {
                return false
            }
            return true
        }
        try assertThrowsParsingError("foo-bar") {
            guard case .unexpectedInput(loc: _, actual: "foo-b", expected: "false") = $0 else {
                return false
            }
            return true
        }
        try assertThrowsParsingError("foo bar") {
            guard case .unexpectedInput(loc: _, actual: "foo b", expected: "false") = $0 else {
                return false
            }
            return true
        }

        try assertKinds("false//hello", .false, .lineComment)
    }

    private func assertKinds(_ jsoncString: String, _ kinds: JSONCScanner.Token.Kind...,
                             in file: StaticString = #file,
                             line: UInt = #line) throws
    {
        let scanner = JSONCScanner(jsoncString: jsoncString)
        for kind in kinds {
            let token = try scanner.scanToken()
            XCTAssertEqual(token.kind, kind, file: file, line: line)
        }
        XCTAssertEqual((try scanner.scanToken()).kind, .eof, file: file, line: line)
    }

    private func assertThrowsParsingError(_ jsoncString: String,
                                          _ kinds: JSONCScanner.Token.Kind...,
                                          assertion: (ParsingError) -> Bool,
                                          in file: StaticString = #file,
                                          line: UInt = #line) throws
    {
        let scanner = JSONCScanner(jsoncString: jsoncString)
        for kind in kinds {
            let token = try scanner.scanToken()
            XCTAssertEqual(token.kind, kind, file: file, line: line)
        }
        var thrownError: Error!
        XCTAssertThrowsError(try scanner.scanToken(), file: file, line: line) { error in
            thrownError = error
        }
        XCTAssertTrue(
            thrownError is ParsingError,
            "Unexpected error type: \(type(of: thrownError))",
            file: file,
            line: line
        )
        XCTAssertTrue(assertion(thrownError as! ParsingError), file: file, line: line)
    }
}
