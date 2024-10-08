import UITestsFoundation
import XCTest

class SupportScreenTests: XCTestCase {

    @MainActor
    override func setUpWithError() throws {
        setUpTestSuite()
    }

    func testSupportForumsCanBeLoadedDuringLogin() throws {
        try PrologueScreen()
            .selectContinue()
            .selectHelp()
            .assertVisitForumButtonEnabled()
            .visitForums()
            .assertForumsLoaded()
    }

    func testContactUsCanBeLoadedDuringLogin() throws {
        try PrologueScreen()
            .selectContinue()
            .selectHelp()
            .contactSupport(userEmail: WPUITestCredentials.contactSupportUserEmail)
            .assertCanNotSendEmptyMessage()
            .enterText("A")
            .assertCanSendMessage()
    }
}
