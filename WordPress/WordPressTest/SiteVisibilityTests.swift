import XCTest
import WebKit
@testable import WordPress

class SiteVisibilityTests: CoreDataTestCase {
    func testEligibleValuesForJetpackBlog() {
        // Given
        let blog = makeJetpackBlog()

        // Then private not eligible
        XCTAssertEqual(SiteVisibility.eligibleValues(for: blog), [.public, .hidden])
    }

    func testEligibleValuesForNonJetpackConnectedBlog() {
        // Given
        let blog = makeBlog()

        // Then private is eligible
        XCTAssertEqual(SiteVisibility.eligibleValues(for: blog), [.public, .hidden, .private])
    }

    // MARK: - Helpers

    func makeBlog() -> Blog {
        let blog = BlogBuilder.buildBlankBlog(in: mainContext)
        blog.isHostedAtWPcom = true
        return blog
    }

    func makeJetpackBlog() -> Blog {
        let blog = makeBlog()
        blog.isHostedAtWPcom = false
        // UI in the app hides visibility settings entirely for self-hosted non-Jetpack blogs
        // so for the purposes of these tests we can assume that if a blog is self-hosted
        // then it's also running Jetpack.
        return blog
    }
}
