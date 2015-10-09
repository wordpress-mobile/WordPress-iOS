import XCTest
@testable import WordPress

class GravatarTest: XCTestCase {
    func testUnknownGravatarUrlMatchesURLWithSubdomainAndQueryParameters() {
        let url = NSURL(string: "https://0.gravatar.com/avatar/ad516503a11cd5ca435acc9bb6523536?s=256&r=G")!
        let gravatar = Gravatar(url)
        XCTAssertNil(gravatar)
    }

    func testUnknownGravatarUrlMatchesURLWithoutSubdomains() {
        let url = NSURL(string: "https://0.gravatar.com/avatar/ad516503a11cd5ca435acc9bb6523536")!
        let gravatar = Gravatar(url)
        XCTAssertNil(gravatar)
    }

    func testIsUnknownGravatarUrlMatchesURLWithHttpSchema() {
        let url = NSURL(string: "http://0.gravatar.com/avatar/ad516503a11cd5ca435acc9bb6523536")!
        let gravatar = Gravatar(url)
        XCTAssertNil(gravatar)
    }

    func testGravatarRejectsIncorrectPath() {
        let url = NSURL(string: "http://0.gravatar.com/5b415e3c9c245e557af9f580eeb8760a")!
        let gravatar = Gravatar(url)
        XCTAssertNil(gravatar)
    }

    func testGravatarRejectsIncorrectHost() {
        let url = NSURL(string: "http://0.argvatar.com/avatar/5b415e3c9c245e557af9f580eeb8760a")!
        let gravatar = Gravatar(url)
        XCTAssertNil(gravatar)
    }

    func testGravatarRemovesQueryParameters() {
        let url = NSURL(string: "https://secure.gravatar.com/avatar/5b415e3c9c245e557af9f580eeb8760a?d=http://0.gravatar.com/5b415e3c9c245e557af9f580eeb8760a")!
        let expected = NSURL(string: "https://secure.gravatar.com/avatar/5b415e3c9c245e557af9f580eeb8760a")!
        let gravatar = Gravatar(url)
        XCTAssertNotNil(gravatar)
        XCTAssertEqual(gravatar!.canonicalURL, expected)
    }

    func testGravatarForcesHTTPS() {
        let url = NSURL(string: "http://0.gravatar.com/avatar/5b415e3c9c245e557af9f580eeb8760a")!
        let expected = NSURL(string: "https://secure.gravatar.com/avatar/5b415e3c9c245e557af9f580eeb8760a")!
        let gravatar = Gravatar(url)
        XCTAssertNotNil(gravatar)
        XCTAssertEqual(gravatar!.canonicalURL, expected)
    }

    func testGravatarAppendsSizeQuery() {
        let url = NSURL(string: "http://0.gravatar.com/avatar/5b415e3c9c245e557af9f580eeb8760a")!
        let expected = NSURL(string: "https://secure.gravatar.com/avatar/5b415e3c9c245e557af9f580eeb8760a?s=128&d=404")!
        let gravatar = Gravatar(url)
        XCTAssertNotNil(gravatar)
        XCTAssertEqual(gravatar!.urlWithSize(128), expected)
    }
}
