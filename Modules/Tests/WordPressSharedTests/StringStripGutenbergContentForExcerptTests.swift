import XCTest
@testable import WordPressShared

class StringStripGutenbergContentForExcerptTests: XCTestCase {

    func testStrippingGutenbergContentForExcerpt() {
        let content = "<p>Some Content</p>"
        let expectedSummary = "<p>Some Content</p>"

        let summary = content.strippingGutenbergContentForExcerpt()

        XCTAssertEqual(summary, expectedSummary)
    }

    func testStrippingGutenbergContentForExcerptWithGallery() {
        let content = "<!-- wp:gallery {\"ids\":[2315,2309,2308]} --><figure class=\"wp-block-gallery columns-3 is-cropped\"><ul class=\"blocks-gallery-grid\"><li class=\"blocks-gallery-item\"><figure><img src=\"https://diegotest4.files.wordpress.com/2020/01/img_0005-1-1.jpg\" data-id=\"2315\" class=\"wp-image-2315\"/><figcaption class=\"blocks-gallery-item__caption\">Asdasdasd</figcaption></figure></li><li class=\"blocks-gallery-item\"><figure><img src=\"https://diegotest4.files.wordpress.com/2020/01/img_0111-1-1.jpg\" data-id=\"2309\" class=\"wp-image-2309\"/><figcaption class=\"blocks-gallery-item__caption\">Asdasdasd</figcaption></figure></li><li class=\"blocks-gallery-item\"><figure><img src=\"https://diegotest4.files.wordpress.com/2020/01/img_0004-1.jpg\" data-id=\"2308\" class=\"wp-image-2308\"/><figcaption class=\"blocks-gallery-item__caption\">Adsasdasdasd</figcaption></figure></li></ul></figure><!-- /wp:gallery --><p>Some Content</p>"
        let expectedSummary = "<p>Some Content</p>"

        let summary = content.strippingGutenbergContentForExcerpt()

        XCTAssertEqual(summary, expectedSummary)
    }

    func testStrippingGutenbergContentForExcerptWithGallery2() {
        let content = "<p>Before</p>\n<!-- wp:gallery {\"ids\":[2315,2309,2308]} --><figure class=\"wp-block-gallery columns-3 is-cropped\"><ul class=\"blocks-gallery-grid\"><li class=\"blocks-gallery-item\"><figure><img src=\"https://diegotest4.files.wordpress.com/2020/01/img_0005-1-1.jpg\" data-id=\"2315\" class=\"wp-image-2315\"/><figcaption class=\"blocks-gallery-item__caption\">Asdasdasd</figcaption></figure></li><li class=\"blocks-gallery-item\"><figure><img src=\"https://diegotest4.files.wordpress.com/2020/01/img_0111-1-1.jpg\" data-id=\"2309\" class=\"wp-image-2309\"/><figcaption class=\"blocks-gallery-item__caption\">Asdasdasd</figcaption></figure></li><li class=\"blocks-gallery-item\"><figure><img src=\"https://diegotest4.files.wordpress.com/2020/01/img_0004-1.jpg\" data-id=\"2308\" class=\"wp-image-2308\"/><figcaption class=\"blocks-gallery-item__caption\">Adsasdasdasd</figcaption></figure></li></ul></figure><!-- /wp:gallery --><p>After</p>"
        let expectedSummary = "<p>Before</p>\n<p>After</p>"

        let summary = content.strippingGutenbergContentForExcerpt()

        XCTAssertEqual(summary, expectedSummary)
    }

    func testStrippingGutenbergContentForExcerptWithVideoPress() {
        let content = "<p>Before</p>\n<!-- wp:videopress/video {\"title\":\"demo\",\"description\":\"\",\"id\":5297,\"guid\":\"AbCDe\",\"videoRatio\":56.333333333333336,\"privacySetting\":2,\"allowDownload\":false,\"rating\":\"G\",\"isPrivate\":true,\"duration\":1673} -->\n<figure class=\"wp-block-videopress-video wp-block-jetpack-videopress jetpack-videopress-player\"><div class=\"jetpack-videopress-player__wrapper\">\nhttps://videopress.com/v/AbCDe?resizeToParent=true&amp;cover=true&amp;preloadContent=metadata&amp;useAverageColor=true\n</div></figure>\n<!-- /wp:videopress/video -->\n<p>After</p>"
        let expectedSummary = "<p>Before</p>\n<p>After</p>"

        let summary = content.strippingGutenbergContentForExcerpt()

        XCTAssertEqual(summary, expectedSummary)
    }

    func testStrippingGutenbergContentForExcerptWithVideoPress2() {
            let content = "<p>Before</p>\n<!-- wp:video {\"guid\":\"AbCDe\",\"id\":5297} -->\n<figure class=\"wp-block-video\"><div class=\"wp-block-embed__wrapper\">\nhttps://videopress.com/v/AbCDe?resizeToParent=true&amp;cover=true&amp;preloadContent=metadata&amp;useAverageColor=true\n</div></figure>\n<!-- /wp:video -->\n<p>After</p>"
            let expectedSummary = "<p>Before</p>\n<p>After</p>"

            let summary = content.strippingGutenbergContentForExcerpt()

            XCTAssertEqual(summary, expectedSummary)
        }
}
