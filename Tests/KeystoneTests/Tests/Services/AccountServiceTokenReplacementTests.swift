import CoreData
import Foundation
import Testing
@testable import WordPress
@testable import WordPressData

/// Signing in again to the default account: the account-changed notification announces the new token.
///
/// Serialized: the tests set the default account.
@Suite(.serialized)
@MainActor
struct AccountServiceTokenReplacementTests {
    private let contextManager = ContextManager.forTesting()

    /// The account is stored through a background context. Observers read it from the main context, which must
    /// already have the new username, because the token is stored under it.
    @Test func newTokenIsReadableWhenAnnouncedAfterAUsernameChange() throws {
        let service = AccountService(coreDataStack: contextManager)
        let user = makeUser(userID: Int.random(in: 100_000...999_999))
        let accountID = service.createOrUpdateAccount(withUserDetails: user, authToken: "old-token")
        let account = try #require(try contextManager.mainContext.existingObject(with: accountID) as? WPAccount)
        UserSettings.defaultDotComUUID = account.uuid
        defer {
            account.authToken = nil
            UserSettings.defaultDotComUUID = nil
        }
        #expect(account.authToken == "old-token")

        let renamedUser = makeUser(userID: user.userID!.intValue)
        var announcedUsername: String?
        var announcedToken: String?
        let observer = NotificationCenter.default.addObserver(
            forName: .wpAccountDefaultWordPressComAccountChanged,
            object: nil,
            queue: nil
        ) { notification in
            guard let announced = notification.object as? WPAccount, announced.objectID == accountID else {
                return
            }
            announcedUsername = announced.username
            announcedToken = announced.authToken
        }
        defer {
            NotificationCenter.default.removeObserver(observer)
        }

        _ = service.createOrUpdateAccount(withUserDetails: renamedUser, authToken: "new-token")

        #expect(announcedUsername == renamedUser.username)
        #expect(announcedToken == "new-token")
    }

    private func makeUser(userID: Int) -> RemoteUser {
        let user = RemoteUser()
        user.userID = NSNumber(value: userID)
        // Unique, because the token goes to the simulator keychain under the username.
        user.username = "user-\(UUID().uuidString)"
        user.email = "user@example.com"
        return user
    }
}
