import XCTest // Wanted to use Testing, but don't yet have CoreData utils there
@testable import WordPress

class WPAccountRestApiTests: CoreDataTestCase {

    func testAccessingAPIWithNoTokenPostsNotification() async {
        let account = WPAccount.fixture(context: mainContext, authToken: "")

        let testNotificationCenter = NotificationCenter()
        account.notificationCenter = testNotificationCenter

        let notificationExpectation = XCTNSNotificationExpectation(
            name: .wpAccountRequiresShowingSigninForWPComFixingAuthToken,
            object: account,
            notificationCenter: testNotificationCenter
        )

        _ = account.wordPressComRestApi

        await fulfillment(of: [notificationExpectation])
    }

    func testAccessingAPIWithTokenDoesNotPostsNotification() async {
        let account = WPAccount.fixture(context: mainContext, authToken: "a-token")

        let testNotificationCenter = NotificationCenter()
        account.notificationCenter = testNotificationCenter

        let notificationExpectation = XCTNSNotificationExpectation(
            name: .wpAccountRequiresShowingSigninForWPComFixingAuthToken,
            object: account,
            notificationCenter: testNotificationCenter
        )
        notificationExpectation.isInverted = true

        _ = account.wordPressComRestApi

        await fulfillment(of: [notificationExpectation])
    }
}
