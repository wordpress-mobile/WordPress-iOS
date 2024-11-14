import Foundation
import Testing

@testable import WordPress

@Suite
struct ZendeskUtilsA8CEmailTests {

    @Test(
        arguments: [
            ("hello@automattic.com", "hello+testing@automattic.com"),
            ("Hello@Automattic.com", "Hello+testing@Automattic.com"),
            ("Hello@a8c.com", "Hello+testing@a8c.com"),
            ("Hello@A8C.com", "Hello+testing@A8C.com"),
        ]
    )
    func insertTesting(email: String, expected: String) {
        let result = ZendeskUtils.a8cTestEmail(email)
        #expect(result == expected)
    }

    @Test(
        arguments: [
            "Hello@world.com",
            "Hello@World.com",
            "Hello+Testing@automattic.com",
            "Hello+World@a8c.com"
        ]
    )
    func keepOriginalEmail(email: String) {
        let result = ZendeskUtils.a8cTestEmail(email)
        #expect(result == email)
    }

}
