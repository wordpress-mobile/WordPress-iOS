import XCTest
@testable import WordPressShared
@testable import WordPressSharedUI

class RichContentFormatterUITests: XCTestCase {

    func testResizeGalleryImageURLsForContentEmptyString() {
        XCTAssertTrue("" == RichContentFormatter.resizeGalleryImageURL("", isPrivateSite: false))
    }

    // The gallery-image src rewrite sized its search range from the grapheme count
    // (`imgElementStr.count`) rather than the UTF-16 length, so a `src` sitting past a
    // multi-code-unit cluster fell outside the range and was never swapped for the resized
    // URL. Here five emoji in `alt` (10 UTF-16 units, 5 graphemes) push the trailing `src`
    // past a grapheme-count range; the resized URL must still replace it, cluster intact.
    func testResizeGalleryImageURLReplacesSrcPastMultibyteCluster() {
        let input =
            "<img data-orig-file=\"https://example.com/orig.jpg\" alt=\"😀😀😀😀😀\" src=\"https://example.com/small.jpg\"/>"

        let output = RichContentFormatter.resizeGalleryImageURL(input, isPrivateSite: false)

        // The original src was found and rewritten to a resized (Photon) URL...
        XCTAssertFalse(output.contains("https://example.com/small.jpg"))
        XCTAssertTrue(output.contains(".wp.com"))
        // ...and the emoji cluster survived byte-for-byte.
        XCTAssertTrue(output.contains("😀😀😀😀😀"))
    }
}
