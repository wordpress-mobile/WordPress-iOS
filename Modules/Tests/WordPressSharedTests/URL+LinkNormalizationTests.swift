import Foundation
import WordPressShared
import Testing

struct URL_WordPressLinkNormalizationTests {

    @Test func testNormalizedURLForWordPressLink() {
        var url = URL(string: "www.wordpress.com")!
        var normalizedURL = url.normalizedURLForWordPressLink()
        #expect("http://www.wordpress.com" == normalizedURL.absoluteString)

        url = URL(string: "wordpress.com")!
        normalizedURL = url.normalizedURLForWordPressLink()
        #expect("http://wordpress.com" == normalizedURL.absoluteString)

        url = URL(string: "wordpress.com/index.html")!
        normalizedURL = url.normalizedURLForWordPressLink()
        #expect("http://wordpress.com/index.html" == normalizedURL.absoluteString)

        url = URL(string: "index.html")!
        normalizedURL = url.normalizedURLForWordPressLink()
        #expect("http://index.html" == normalizedURL.absoluteString)

        url = URL(string: "/index.html")!
        normalizedURL = url.normalizedURLForWordPressLink()
        #expect("/index.html" == normalizedURL.absoluteString)
    }
}
