@testable import WordPressAuthenticator
import XCTest

class DataSHA256Tests: XCTestCase {

    func testSHA256Hasing() {
        // It's fiddly to test the hashing `Data` against `Data`, so we use `String` against
        // `String` and we trust/hope that the underlying implementation is shared.
        XCTAssertEqual(
            Data("foo".utf8).sha256Hashed(),
            "2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae"
        )
        XCTAssertEqual(
            Data("Hello, World!".utf8).sha256Hashed(),
            "dffd6021bb2bd5b0af676290809ec3a53191dd81c7f70a4b28688a362182986f"
        )
        XCTAssertEqual(
            Data("abcABC-=/?".utf8).sha256Hashed(),
            "e8552e6ddda2103b18158c28ecd834b1772c72794011547c9ef6d8fcb3419a23"
        )
    }
}
