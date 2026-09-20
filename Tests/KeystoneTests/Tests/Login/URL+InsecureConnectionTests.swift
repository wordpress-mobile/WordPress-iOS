import Foundation
import Testing

@testable import WordPress

struct URLInsecureConnectionTests {
    @Test(arguments: [
        "https://example.com",
        "https://example.com:8443/wp-json",
        "HTTPS://EXAMPLE.COM"
    ])
    func secureURLs(_ string: String) throws {
        let url = try #require(URL(string: string))
        #expect(!url.isInsecureConnection)
    }

    @Test(arguments: [
        "http://example.com",
        "HTTP://EXAMPLE.COM",
        "http://example.com:8080/wp-json",
        "http://mymac.local",
        "http://mysite.test",
        "http://192.168.1.10:8881"
    ])
    func insecureURLs(_ string: String) throws {
        let url = try #require(URL(string: string))
        #expect(url.isInsecureConnection)
    }

    @Test(arguments: [
        "http://localhost",
        "http://localhost:8881/wp-admin",
        "http://LOCALHOST:8881",
        "http://127.0.0.1:8881",
        "http://[::1]:8881"
    ])
    func loopbackURLsAreExempt(_ string: String) throws {
        let url = try #require(URL(string: string))
        #expect(!url.isInsecureConnection)
    }
}
