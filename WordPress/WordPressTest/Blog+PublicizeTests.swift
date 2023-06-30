import Foundation
import XCTest

@testable import WordPress

final class Blog_PublicizeTests: CoreDataTestCase {

    func testAutoSharingInfoForDotComBlog() {
        let blog = makeBlog(hostedAtWPCom: true, activeSocialFeature: false)

        // all dotcom sites should have no sharing limitations.
        XCTAssertFalse(blog.isSocialSharingLimited)
    }

    func testAutoSharingInfoForDotComBlogWithStoredSharingLimit() {
        // unlikely case, but let's test anyway.
        let blog = makeBlog(hostedAtWPCom: true, activeSocialFeature: false, hasPreExistingData: true)

        XCTAssertFalse(blog.isSocialSharingLimited)
        XCTAssertNil(blog.sharingLimit)
    }

    func testAutoSharingInfoForSelfHostedBlog() {
        let blog = makeBlog(hostedAtWPCom: false, activeSocialFeature: false)

        XCTAssertTrue(blog.isSocialSharingLimited)
    }

    func testAutoSharingInfoForSelfHostedBlogWithStoredSharingLimit() {
        let blog = makeBlog(hostedAtWPCom: false, activeSocialFeature: false, hasPreExistingData: true)

        XCTAssertNotNil(blog.sharingLimit)
    }

    func testAutoSharingInfoForSelfHostedBlogWithSocialFeature() {
        let blog = makeBlog(hostedAtWPCom: false, activeSocialFeature: true)

        XCTAssertFalse(blog.isSocialSharingLimited)
    }

    func testAutoSharingInfoForSelfHostedBlogWithSocialFeatureAndStoredSharingLimit() {
        // Example: a free site purchased an individual Social Basic plan. In this case, there should still be a
        // `PublicizeInfo` data stored in Core Data, but the blog might still have the social feature active.
        let blog = makeBlog(hostedAtWPCom: false, activeSocialFeature: true, hasPreExistingData: true)

        // the sharing limit should be nil regardless of the existence of stored data.
        XCTAssertNil(blog.sharingLimit)
    }

    // MARK: - Helpers

    private func makeBlog(hostedAtWPCom: Bool, activeSocialFeature: Bool, hasPreExistingData: Bool = false) -> Blog {
        let blog = BlogBuilder(mainContext)
            .with(isHostedAtWPCom: hostedAtWPCom)
            .with(planActiveFeatures: activeSocialFeature ? ["social-shares-1000"] : [])
            .build()

        if hasPreExistingData {
            let publicizeInfo = PublicizeInfo(context: mainContext)
            publicizeInfo.shareLimit = 30
            publicizeInfo.sharesRemaining = 25
            blog.publicizeInfo = publicizeInfo
        }

        return blog
    }

}
