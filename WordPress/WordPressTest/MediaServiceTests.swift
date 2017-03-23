import XCTest
@testable import WordPress

class MediaServiceTests: XCTestCase {

    func testThatLocalMediaDirectoryIsAvailable() {
        do {
            let url = try MediaService.localMediaDirectory()
            XCTAssertTrue(url.lastPathComponent == "Media", "Error: local media directory is not named Media, as expected.")
        } catch {
            XCTFail("Error accessing or creating local media directory")
        }
    }
}
