import Foundation
import Testing

@testable import WordPress

struct UniversalLinkRouterTests {

    @Test(
        arguments: [
            "http://en.blog.wordpress.com/2025/11/26/wordpress-migration-checklist/",
        ]
    )
    func supportPostLinks(url: String) {
        let router = UniversalLinkRouter.shared
        #expect(router.canHandle(url: URL(string: url)!))
    }

}
