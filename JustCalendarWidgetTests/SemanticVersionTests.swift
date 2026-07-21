import XCTest
@testable import Just_Calendar_Widget

final class SemanticVersionTests: XCTestCase {
    func testReleaseTagParsesWithOptionalPrefix() throws {
        let plainVersion = try XCTUnwrap(SemanticVersion(tag: "1.2.3"))
        let taggedVersion = try XCTUnwrap(SemanticVersion(tag: "v1.2.3"))

        XCTAssertEqual(plainVersion, taggedVersion)
        XCTAssertEqual(taggedVersion.displayString, "1.2.3")
    }

    func testVersionsCompareByAllThreeComponents() throws {
        let current = try XCTUnwrap(SemanticVersion(tag: "1.9.12"))
        let nextMinor = try XCTUnwrap(SemanticVersion(tag: "1.10.0"))
        let nextMajor = try XCTUnwrap(SemanticVersion(tag: "2.0.0"))

        XCTAssertLessThan(current, nextMinor)
        XCTAssertLessThan(nextMinor, nextMajor)
    }

    func testMalformedVersionIsRejected() {
        XCTAssertNil(SemanticVersion(tag: "1.2"))
        XCTAssertNil(SemanticVersion(tag: "v1.two.3"))
        XCTAssertNil(SemanticVersion(tag: "preview"))
    }
}
