import XCTest

class JSONObjectTests: XCTestCase {
    func testParsingFileWithUnexpectedFileExtension() throws {
        try XCTAssertThrowsError(JSONObject(fromFileNamed: "notifications.josn"))
    }

    func testParsingNonexistentFiles() throws {
        try XCTAssertThrowsError(JSONObject(fromFileNamed: "a-file-that-does-not-exist"))
        try XCTAssertThrowsError(JSONObject(fromFileNamed: "a-file-that-does-not-exist.json"))
    }

    func testAllowedFileNames() throws {
        try XCTAssertNoThrow(JSONObject(fromFileNamed: "authtoken"))
        try XCTAssertNoThrow(JSONObject(fromFileNamed: "authtoken.json"))
    }
}
