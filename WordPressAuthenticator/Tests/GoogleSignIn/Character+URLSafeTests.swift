@testable import WordPressAuthenticator
import Foundation
import XCTest

class Character_URLSafeTests: XCTestCase {

    func testURLSafeCharacters() throws {
        let urlSafe = CharacterSet(Character.urlSafeCharacters.map { "\($0)" }.joined().unicodeScalars)

        // Ensure `Character.urlSafeCharacters` is a subset of `CharacterSet.urlQueryAllowed`
        XCTAssertTrue(urlSafe.isStrictSubset(of: CharacterSet.urlQueryAllowed))

        // Notice that `CharacterSet.urlQueryAllowed` is not a subset of
        // `Character.urlSafeCharacters`, though, because URL queries allow characters such as &.
        XCTAssertFalse(CharacterSet.urlQueryAllowed.isStrictSubset(of: urlSafe))
    }
}
