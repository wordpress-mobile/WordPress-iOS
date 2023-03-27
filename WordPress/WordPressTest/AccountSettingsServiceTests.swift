import XCTest
import Nimble
import OHHTTPStubs

@testable import WordPress

class AccountSettingsServiceTests: CoreDataTestCase {
    private var service: AccountSettingsService!

    override func setUp() {
        let account = WPAccount(context: mainContext)
        account.username = "test"
        account.authToken = "token"
        account.userID = 1
        account.uuid = UUID().uuidString

        let settings = ManagedAccountSettings(context: mainContext)
        settings.account = account
        settings.username = "Username"
        settings.displayName = "Display Name"
        settings.primarySiteID = 1
        settings.aboutMe = "<empty>"
        settings.email = "test@email.com"
        settings.firstName = "Test"
        settings.lastName = "User"
        settings.language = "en"
        settings.webAddress = "https://test.wordpress.com"

        contextManager.saveContextAndWait(mainContext)

        service = AccountSettingsService(
            userID: account.userID.intValue,
            remote: AccountSettingsRemote(wordPressComRestApi: account.wordPressComRestApi),
            coreDataStack: contextManager
        )
    }

    private func managedAccountSettings() -> ManagedAccountSettings? {
        contextManager.performQuery { context in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedAccountSettings.entityName())
            request.predicate = NSPredicate(format: "account.userID = %d", self.service.userID)
            request.fetchLimit = 1
            guard let results = (try? context.fetch(request)) as? [ManagedAccountSettings] else {
                return nil
            }
            return results.first
        }
    }

    func testUpdateSuccess() throws {
        stub(condition: isPath("/rest/v1.1/me/settings")) { _ in
            HTTPStubsResponse(jsonObject: [:], statusCode: 200, headers: nil)
        }
        waitUntil { done in
            self.service.saveChange(.firstName("Updated"), finished: { success in
                expect(success).to(beTrue())
                done()
            })
        }
        expect(self.managedAccountSettings()?.firstName).to(equal("Updated"))
    }

    func testUpdateFailure() throws {
        stub(condition: isPath("/rest/v1.1/me/settings")) { _ in
            HTTPStubsResponse(jsonObject: [:], statusCode: 500, headers: nil)
        }
        waitUntil { done in
            self.service.saveChange(.firstName("Updated"), finished: { success in
                expect(success).to(beFalse())
                done()
            })
        }
        expect(self.managedAccountSettings()?.firstName).to(equal("Test"))
    }

    func testCancelGettingSettings() throws {
        // This test performs steps described in the link below to reproduce a crash.
        // https://github.com/wordpress-mobile/WordPress-iOS/issues/20379#issuecomment-1481995663

        let apiFired = expectation(description: "Get settings API fired")
        stub(condition: isPath("/rest/v1.1/me/settings")) { _ in
            apiFired.fulfill()
            // Simulate a slow HTTP response, so that the test code below has a chance to
            // cancel this API request
            sleep(2)
            return HTTPStubsResponse(jsonObject: [:], statusCode: 500, headers: nil)
        }
        service.getSettingsAttempt()

        wait(for: [apiFired], timeout: 0.5)

        // Delete the logged in account, which would cause the URLSession used in the `service` to
        // cancell all ongoing tasks, including the "get settings" one above.
        let account = try XCTUnwrap(WPAccount.lookup(withUserID: 1, in: contextManager.mainContext))
        contextManager.mainContext.delete(account)
        contextManager.saveContextAndWait(contextManager.mainContext)

        let notCrash = expectation(description: "Not crash")
        notCrash.isInverted = true
        wait(for: [notCrash], timeout: 0.5)
    }
}
