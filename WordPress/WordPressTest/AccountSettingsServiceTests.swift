import XCTest
import Nimble
import OHHTTPStubs

@testable import WordPress

class AccountSettingsServiceTests: CoreDataTestCase {
    private var service: AccountSettingsService!

    override func setUp() {
        let account = WPAccount(context: mainContext)
        account.username = "test"
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
            remote: AccountSettingsRemote(wordPressComRestApi: WordPressComRestApi()),
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
}
