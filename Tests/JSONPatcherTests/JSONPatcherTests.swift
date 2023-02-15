@testable import JSONPatcher
import XCTest

final class JSONPatcherTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testStripComments() throws {
        let patcher = try JSONPatcher(original: "//comment\n[1, 42.0, /*\"Hello\", */\"World\"\n\t]")
        XCTAssertEqual(patcher.json(), "\n[1, 42.0, \"World\"\n\t]")
    }
}
