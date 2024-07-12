import XCTest
@testable import WordPressShared

class NSStringSummaryTests: XCTestCase {

    func testSummaryForContent() {
        let content = "<p>Lorem ipsum dolor sit amet, [shortcode param=\"value\"]consectetur[/shortcode] adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p> <p>Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.</p><p>Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.</p><p>Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>"
        let expectedSummary = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, …"

        let summary = content.summarized()

        XCTAssertEqual(summary, expectedSummary)
    }

    func testSummaryForContentWithGallery() {
        let content = "<!-- wp:gallery {\"ids\":[2315,2309,2308]} --><figure class=\"wp-block-gallery columns-3 is-cropped\"><ul class=\"blocks-gallery-grid\"><li class=\"blocks-gallery-item\"><figure><img src=\"https://diegotest4.files.wordpress.com/2020/01/img_0005-1-1.jpg\" data-id=\"2315\" class=\"wp-image-2315\"/><figcaption class=\"blocks-gallery-item__caption\">Asdasdasd</figcaption></figure></li><li class=\"blocks-gallery-item\"><figure><img src=\"https://diegotest4.files.wordpress.com/2020/01/img_0111-1-1.jpg\" data-id=\"2309\" class=\"wp-image-2309\"/><figcaption class=\"blocks-gallery-item__caption\">Asdasdasd</figcaption></figure></li><li class=\"blocks-gallery-item\"><figure><img src=\"https://diegotest4.files.wordpress.com/2020/01/img_0004-1.jpg\" data-id=\"2308\" class=\"wp-image-2308\"/><figcaption class=\"blocks-gallery-item__caption\">Adsasdasdasd</figcaption></figure></li></ul></figure><!-- /wp:gallery --><p>Some Content</p>"
        let expectedSummary = "Some Content"

        let summary = content.summarized()

        XCTAssertEqual(summary, expectedSummary)
    }

    func testSummaryForContentWithGallery2() {
        let content = "<p>Before</p>\n<!-- wp:gallery {\"ids\":[2315,2309,2308]} --><figure class=\"wp-block-gallery columns-3 is-cropped\"><ul class=\"blocks-gallery-grid\"><li class=\"blocks-gallery-item\"><figure><img src=\"https://diegotest4.files.wordpress.com/2020/01/img_0005-1-1.jpg\" data-id=\"2315\" class=\"wp-image-2315\"/><figcaption class=\"blocks-gallery-item__caption\">Asdasdasd</figcaption></figure></li><li class=\"blocks-gallery-item\"><figure><img src=\"https://diegotest4.files.wordpress.com/2020/01/img_0111-1-1.jpg\" data-id=\"2309\" class=\"wp-image-2309\"/><figcaption class=\"blocks-gallery-item__caption\">Asdasdasd</figcaption></figure></li><li class=\"blocks-gallery-item\"><figure><img src=\"https://diegotest4.files.wordpress.com/2020/01/img_0004-1.jpg\" data-id=\"2308\" class=\"wp-image-2308\"/><figcaption class=\"blocks-gallery-item__caption\">Adsasdasdasd</figcaption></figure></li></ul></figure><!-- /wp:gallery --><p>After</p>"
        let expectedSummary = "Before\nAfter"

        let summary = content.summarized()

        XCTAssertEqual(summary, expectedSummary)
    }
}
