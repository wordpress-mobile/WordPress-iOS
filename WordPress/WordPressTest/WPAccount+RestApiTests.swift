import XCTest // Wanted to use Testing, but don't yet have CoreData utils there
@testable import WordPress

class WPAccountRestApiTests: CoreDataTestCase {

    func testAccessingAPIWithNoTokenPostsNotification() async {
        let account = WPAccount.fixture(context: mainContext, authToken: "")

        let notificationExpectation = XCTNSNotificationExpectation(
            name: .wpAccountRequiresShowingSigninForWPComFixingAuthToken,
            object: account,
            notificationCenter: .default
        )

        _ = account.wordPressComRestApi

        await fulfillment(of: [notificationExpectation])
    }

    func testAccessingAPIWithTokenDoesNotPostsNotification() async {
        let account = WPAccount.fixture(context: mainContext, authToken: "a-token")

        let notificationExpectation = XCTNSNotificationExpectation(
            name: .wpAccountRequiresShowingSigninForWPComFixingAuthToken,
            object: account,
            notificationCenter: .default
        )
        notificationExpectation.isInverted = true

        _ = account.wordPressComRestApi

        await fulfillment(of: [notificationExpectation], timeout: 0.1)
    }
}
