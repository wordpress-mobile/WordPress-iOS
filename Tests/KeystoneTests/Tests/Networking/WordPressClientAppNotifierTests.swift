import WordPressAPI
import WordPressCore
import XCTest
@testable import WordPress
@testable import WordPressData

final class WordPressClientAppNotifierTests: CoreDataTestCase {
    func testRejectionThroughWordPressComRequestsTheWordPressComSignIn() async throws {
        let blogID = TaggedManagedObjectID(BlogBuilder(mainContext).build())
        let site = WordPressSite(
            blogId: blogID,
            siteURL: URL(string: "https://example.wordpress.com")!,
            flavor: .dotCom(.init(siteId: 1, oAuthToken: "a-token", applicationPassword: nil))
        )

        let signIn = XCTNSNotificationExpectation(
            name: .wpAccountRequiresShowingSigninForWPComFixingAuthToken,
            object: nil,
            notificationCenter: .default
        )
        let applicationPasswordReauthentication = XCTNSNotificationExpectation(
            name: WordPressClient.requestedWithInvalidAuthenticationNotification,
            object: nil,
            notificationCenter: .default
        )
        applicationPasswordReauthentication.isInverted = true

        await AppNotifier(site: site, coreDataStack: contextManager)
            .requestedWithInvalidAuthentication(requestUrl: "https://public-api.wordpress.com/wp/v2/sites/1/posts")

        await fulfillment(of: [signIn, applicationPasswordReauthentication], timeout: 0.5)
    }

    func testRejectionOfApplicationPasswordRequestsItsReauthentication() async throws {
        let blogID = TaggedManagedObjectID(BlogBuilder(mainContext, dotComID: nil).build())
        let site = WordPressSite(
            blogId: blogID,
            siteURL: URL(string: "https://example.com")!,
            flavor: .selfHosted(
                .init(
                    apiRootURL: try ParsedUrl.from(url: URL(string: "https://example.com/wp-json/")!),
                    username: "user",
                    token: "an-application-password"
                )
            )
        )

        let applicationPasswordReauthentication = XCTNSNotificationExpectation(
            name: WordPressClient.requestedWithInvalidAuthenticationNotification,
            object: nil,
            notificationCenter: .default
        )
        applicationPasswordReauthentication.handler = { notification in
            notification.object as? TaggedManagedObjectID<Blog> == blogID
        }
        let signIn = XCTNSNotificationExpectation(
            name: .wpAccountRequiresShowingSigninForWPComFixingAuthToken,
            object: nil,
            notificationCenter: .default
        )
        signIn.isInverted = true

        await AppNotifier(site: site, coreDataStack: contextManager)
            .requestedWithInvalidAuthentication(requestUrl: "https://example.com/wp-json/wp/v2/posts")

        await fulfillment(of: [applicationPasswordReauthentication, signIn], timeout: 0.5)
    }
}
