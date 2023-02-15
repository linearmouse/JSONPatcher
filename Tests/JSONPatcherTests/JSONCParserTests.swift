@testable import JSONPatcher
import XCTest

final class JSONCParserTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testParse() throws {
        XCTAssertEqual(try JSONCParser(jsoncString: "//comment\n[1, 42.0, /*\"Hello\", */\"World\"]").parse().encode(), "[1,42.0,\"World\"]")
    }
}
