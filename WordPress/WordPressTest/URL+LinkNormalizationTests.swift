import XCTest

class URL_WordPressLinkNormalizationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testNormalizedURLForWordPressLink() {
        var url = URL(string: "www.wordpress.com")!
        var normalizedURL = url.normalizedURLForWordPressLink()
        XCTAssertEqual("http://www.wordpress.com", normalizedURL.absoluteString)

        url = URL(string: "wordpress.com")!
        normalizedURL = url.normalizedURLForWordPressLink()
        XCTAssertEqual("http://wordpress.com", normalizedURL.absoluteString)

        url = URL(string: "wordpress.com/index.html")!
        normalizedURL = url.normalizedURLForWordPressLink()
        XCTAssertEqual("http://wordpress.com/index.html", normalizedURL.absoluteString)

        url = URL(string: "index.html")!
        normalizedURL = url.normalizedURLForWordPressLink()
        XCTAssertEqual("http://index.html", normalizedURL.absoluteString)

        url = URL(string: "/index.html")!
        normalizedURL = url.normalizedURLForWordPressLink()
        XCTAssertEqual("/index.html", normalizedURL.absoluteString)
    }

}
