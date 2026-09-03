import Foundation
import Testing

@testable import WordPressShared
@testable import WordPressSharedUI

struct RichContentFormatterUITests {

    @Test func testResizeGalleryImageURLsForContentEmptyString() {
        #expect(RichContentFormatter.resizeGalleryImageURL("", isPrivateSite: false).isEmpty)
    }

    // The gallery-image src rewrite sized its search range from the grapheme count
    // (`imgElementStr.count`) rather than the UTF-16 length, so a `src` sitting past a
    // multi-code-unit cluster fell outside the range and was never swapped for the resized
    // URL. Here five emoji in `alt` (10 UTF-16 units, 5 graphemes) push the trailing `src`
    // past a grapheme-count range; the resized URL must still replace it, cluster intact.
    @Test func testResizeGalleryImageURLReplacesSrcPastMultibyteCluster() {
        let input =
            "<img data-orig-file=\"https://example.com/orig.jpg\" alt=\"😀😀😀😀😀\" src=\"https://example.com/small.jpg\"/>"

        let output = RichContentFormatter.resizeGalleryImageURL(input, isPrivateSite: false)

        // The original src was found and rewritten to a resized (Photon) URL...
        #expect(!output.contains("https://example.com/small.jpg"))
        #expect(output.contains(".wp.com"))
        // ...and the emoji cluster survived byte-for-byte.
        #expect(output.contains("😀😀😀😀😀"))
    }

    @Test func testResizeGalleryImageURLLeavesSrcsetIntact() {
        // The src value also appears in srcset; only the src attribute should be rewritten.
        let srcset = "srcset=\"https://example.com/a.jpg 1x, https://example.com/b.jpg 2x\""
        let input =
            "<img src=\"https://example.com/a.jpg\" \(srcset) data-orig-file=\"https://example.com/orig.jpg\" />"
        let output = RichContentFormatter.resizeGalleryImageURL(input, isPrivateSite: false)
        #expect(output.contains(srcset), "srcset must be left intact when the src is resized")
    }
}
