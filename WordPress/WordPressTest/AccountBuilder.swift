import Foundation

@testable import WordPress

/// Builds an Account for use with testing
///
@objc
class AccountBuilder: NSObject {
    private var account: WPAccount

    @objc
    init(_ context: NSManagedObjectContext) {
        account = NSEntityDescription.insertNewObject(forEntityName: WPAccount.entityName(), into: context) as! WPAccount
        account.uuid = UUID().uuidString

        super.init()
    }

    @objc
    func with(id: Int64) -> AccountBuilder {
        account.userID = NSNumber(value: id)
        return self
    }

    @objc
    func with(uuid: String) -> AccountBuilder {
        account.uuid = uuid
        return self
    }

    @objc
    func with(username: String) -> AccountBuilder {
        account.username = username
        return self
    }

    @objc
    func with(displayName: String) -> AccountBuilder {
        account.displayName = displayName
        return self
    }

    @objc
    func with(email: String) -> AccountBuilder {
        account.email = email
        return self
    }

    @objc
    func with(blogs: [Blog]) -> AccountBuilder {
        account.blogs = Set(blogs)
        return self
    }

    @objc
    func with(authToken: String) -> AccountBuilder {
        account.authToken = authToken

        guard account.authToken != nil else {
            // Setting the token has implicit dependencies on other WPAccount properties as well
            // as the keychain.
            fatalError("Setting the WPAccount authToken failed.")
        }

        return self
    }

    @objc
    @discardableResult
    func build() -> WPAccount {
        account
    }
}
