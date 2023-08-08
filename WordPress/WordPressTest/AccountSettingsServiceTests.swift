import Nimble
import OHHTTPStubs
@testable import WordPress
import XCTest

class AccountSettingsServiceTests: CoreDataTestCase {
    private var service: AccountSettingsService!

    override func setUp() {
        let account = WPAccount.fixture(context: mainContext)
        _ = makeManagedAccountSettings(context: mainContext, account: account)
        contextManager.saveContextAndWait(mainContext)
        service = makeService(contextManager: contextManager, account: account)

        service = AccountSettingsService(
            userID: account.userID.intValue,
            remote: AccountSettingsRemote(wordPressComRestApi: account.wordPressComRestApi),
            coreDataStack: contextManager
        )
    }

    func testUpdateSuccess() throws {
        // We've seen some flakiness in CI on this test, and therefore are using a stub object rather than stubbing the HTTP requests.
        // Since this approach bypasses the entire network stack, the hope is that it'll result in a more robust test.
        //
        // This is the second test in this class edited this way.
        // If we'll need to update a third, we shall also take the time to update the rest of the tests.
        let service = AccountSettingsService(
            userID: 1,
            remote: AccountSettingsRemoteInterfaceStub(updateSettingResult: .success(())),
            coreDataStack: contextManager
        )

        waitUntil { done in
            service.saveChange(.firstName("Updated"), finished: { success in
                expect(success).to(beTrue())
                done()
            })
        }

        expect(self.managedAccountSettings()?.firstName).to(equal("Updated"))
    }

    func testUpdateFailure() throws {
        // We've seen some flakiness in CI on this test, and therefore are using a stub object rather than stubbing the HTTP requests.
        // Since this approach bypasses the entire network stack, the hope is that it'll result in a more robust test.
        let service = AccountSettingsService(
            userID: 1,
            remote: AccountSettingsRemoteInterfaceStub(updateSettingResult: .failure(testError())),
            coreDataStack: contextManager
        )

        waitUntil { done in
            service.saveChange(.firstName("Updated"), finished: { success in
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
            return HTTPStubsResponse(jsonObject: [String: Any](), statusCode: 500, headers: nil)
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

extension AccountSettingsServiceTests {

    private func makeManagedAccountSettings(
        context: NSManagedObjectContext,
        account: WPAccount
    ) -> ManagedAccountSettings {
        let settings = ManagedAccountSettings(context: context)
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
        return settings
    }

    private func makeService(contextManager: ContextManager, account: WPAccount) -> AccountSettingsService {
        AccountSettingsService(
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
}
