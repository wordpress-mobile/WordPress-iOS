import Testing
@testable import WordPressShared

struct GutenbergPostExcerptGeneratorTests {

    @Test func summaryForContent() {
        let content = "<p>Lorem ipsum dolor sit amet, [shortcode param=\"value\"]consectetur[/shortcode] adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p> <p>Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.</p><p>Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.</p><p>Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>"

        let summary = GutenbergExcerptGenerator.firstParagraph(from: content, maxLength: 40)
        #expect(summary == "Lorem ipsum dolor sit amet, consectetur…")
    }

    @Test func summaryForContentWithGallery() {
        let content = "<!-- wp:gallery {\"ids\":[2315,2309,2308]} --><figure class=\"wp-block-gallery columns-3 is-cropped\"><ul class=\"blocks-gallery-grid\"><li class=\"blocks-gallery-item\"><figure><img src=\"https://diegotest4.files.wordpress.com/2020/01/img_0005-1-1.jpg\" data-id=\"2315\" class=\"wp-image-2315\"/><figcaption class=\"blocks-gallery-item__caption\">Asdasdasd</figcaption></figure></li><li class=\"blocks-gallery-item\"><figure><img src=\"https://diegotest4.files.wordpress.com/2020/01/img_0111-1-1.jpg\" data-id=\"2309\" class=\"wp-image-2309\"/><figcaption class=\"blocks-gallery-item__caption\">Asdasdasd</figcaption></figure></li><li class=\"blocks-gallery-item\"><figure><img src=\"https://diegotest4.files.wordpress.com/2020/01/img_0004-1.jpg\" data-id=\"2308\" class=\"wp-image-2308\"/><figcaption class=\"blocks-gallery-item__caption\">Adsasdasdasd</figcaption></figure></li></ul></figure><!-- /wp:gallery --><p>Some Content</p>"

        let summary = GutenbergExcerptGenerator.firstParagraph(from: content, maxLength: 150)
        #expect(summary == "Some Content")
    }

    @Test func summaryForContentWithGallery2() {
        let content = "<p>Before</p>\n<!-- wp:gallery {\"ids\":[2315,2309,2308]} --><figure class=\"wp-block-gallery columns-3 is-cropped\"><ul class=\"blocks-gallery-grid\"><li class=\"blocks-gallery-item\"><figure><img src=\"https://diegotest4.files.wordpress.com/2020/01/img_0005-1-1.jpg\" data-id=\"2315\" class=\"wp-image-2315\"/><figcaption class=\"blocks-gallery-item__caption\">Asdasdasd</figcaption></figure></li><li class=\"blocks-gallery-item\"><figure><img src=\"https://diegotest4.files.wordpress.com/2020/01/img_0111-1-1.jpg\" data-id=\"2309\" class=\"wp-image-2309\"/><figcaption class=\"blocks-gallery-item__caption\">Asdasdasd</figcaption></figure></li><li class=\"blocks-gallery-item\"><figure><img src=\"https://diegotest4.files.wordpress.com/2020/01/img_0004-1.jpg\" data-id=\"2308\" class=\"wp-image-2308\"/><figcaption class=\"blocks-gallery-item__caption\">Adsasdasdasd</figcaption></figure></li></ul></figure><!-- /wp:gallery --><p>After</p>"

        let summary = GutenbergExcerptGenerator.firstParagraph(from: content, maxLength: 150)
        #expect(summary == "Before")
    }

    @Test
    func testVideoPressBlock() {
        let content = "<p>Before</p>\n<!-- wp:videopress/video {\"title\":\"demo\",\"description\":\"\",\"id\":5297,\"guid\":\"AbCDe\",\"videoRatio\":56.333333333333336,\"privacySetting\":2,\"allowDownload\":false,\"rating\":\"G\",\"isPrivate\":true,\"duration\":1673} -->\n<figure class=\"wp-block-videopress-video wp-block-jetpack-videopress jetpack-videopress-player\"><div class=\"jetpack-videopress-player__wrapper\">\nhttps://videopress.com/v/AbCDe?resizeToParent=true&amp;cover=true&amp;preloadContent=metadata&amp;useAverageColor=true\n</div></figure>\n<!-- /wp:videopress/video -->\n<p>After</p>"

        let summary = GutenbergExcerptGenerator.firstParagraph(from: content, maxLength: 150)
        #expect(summary == "Before")
    }
}
