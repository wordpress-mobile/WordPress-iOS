import Foundation
import CoreData
import SFHFKeychainUtils
import CocoaLumberjackSwift
import WordPressShared

@objc(WPAccount)
public class WPAccount: NSManagedObject {
    private var cachedToken: String?
    private var _wordPressComRestApi: WordPressComRestApi?

    private(set) var wordPressComRestApi: WordPressComRestApi? {
        set {
            _wordPressComRestApi = nil
        }
        get {
            guard let authToken, !authToken.isEmpty else {
                NotificationCenter.default.post(
                    name: .wpAccountRequiresShowingSigninForWPComFixingAuthToken,
                    object: self
                )
                return nil
            }

            let api = makeWordPressComRestApi(authToken: authToken)
            self._wordPressComRestApi = api
            return api
        }
    }

    private func makeWordPressComRestApi(authToken: String) -> WordPressComRestApi {
        let api = WordPressComRestApi.defaultApi(
            oAuthToken: authToken,
            userAgent: WPUserAgent.wordPress(),
            localeKey: WordPressComRestApi.LocaleKeyDefault
        )

        let accountID = TaggedManagedObjectID(self)
        let context = managedObjectContext
        wpAssert(context != nil)

        api.setInvalidTokenHandler {
            // We use a static function here because it's not safe to access `self` in this closure.
            // The `WPAccount` instance can be bound to any context object. There is no guarantee that the thread
            // from which this closure is called is the same as the one in the context object.
            context?.perform {
                WPAccount.handleInvalidToken(accountID: accountID, context: context)
            }
        }

        return api
    }

    override public func prepareForDeletion() {
        if managedObjectContext?.concurrencyType == .mainQueueConcurrencyType {
            wordPressComRestApi?.invalidateAndCancelTasks()
            wordPressComRestApi = nil
            authToken = nil
        }
    }

    override public func didTurnIntoFault() {
        super.didTurnIntoFault()
        wordPressComRestApi = nil
        cachedToken = nil
    }

    public var authToken: String? {
        get {
            if let cachedToken {
                return cachedToken
            }

            cachedToken = try? WPAccount.token(forUsername: username)
            return cachedToken
        }
        set {
            cachedToken = nil

            if let authToken = newValue {
                do {
                    try SFHFKeychainUtils.storeUsername(username,
                                                        andPassword: authToken,
                                                        forServiceName: WPAccount.authKeychainServiceName(),
                                                        accessGroup: nil,
                                                        updateExisting: true)
                } catch {
                    DDLogError("Error while updating WordPressComOAuthKeychainServiceName token: \(error)")
                }
            } else {
                do {
                    try SFHFKeychainUtils.deleteItem(forUsername: username,
                                                     andServiceName: WPAccount.authKeychainServiceName(),
                                                     accessGroup: nil)
                } catch {
                    DDLogError("Error while deleting WordPressComOAuthKeychainServiceName token: \(error)")
                }
            }

            wordPressComRestApi = nil
        }
    }
}

// MARK: - Constants

public extension WPAccount {
    @NSManaged var userID: NSNumber?
    @NSManaged var avatarURL: String?
    @NSManaged var username: String
    @NSManaged var uuid: String?
    @NSManaged var dateCreated: Date?
    @NSManaged var email: String?
    @NSManaged var displayName: String?
    @NSManaged var emailVerified: NSNumber?
    @NSManaged var primaryBlogID: NSNumber?
    @NSManaged var blogs: Set<Blog>?
    @NSManaged var defaultBlog: Blog?
    @NSManaged var settings: ManagedAccountSettings?

    override class func entityName() -> String {
        "Account"
    }
}

// MARK: - Relationship Accessors

extension WPAccount {
    @objc(addBlogsObject:)
    @NSManaged public func addToBlogs(_ value: Blog)

    @objc(removeBlogsObject:)
    @NSManaged public func removeFromBlogs(_ value: Blog)

    @objc(addBlogs:)
    @NSManaged public func addToBlogs(_ values: NSSet)

    @objc(removeBlogs:)
    @NSManaged public func removeFromBlogs(_ values: NSSet)
}

extension WPAccount {

    static func token(forUsername username: String, isJetpack: Bool) throws -> String {
        if isJetpack {
            Migration.shared.migrate(username: username)
        }

        do {
            return try SFHFKeychainUtils.getPasswordForUsername(
                username,
                andServiceName: WPAccount.authKeychainServiceName,
                accessGroup: nil
            )
        } catch {
            DDLogError("Error while retrieving WordPressComOAuthKeychainServiceName token: %\(error)")
            throw error
        }
    }

}

private class Migration {
    static let shared = Migration()

    private let lock = NSLock()
    private var migrated: Set<String> = []
    private let instance = SharedDataIssueSolver.instance()

    private init() {}

    func migrate(username: String) {
        lock.lock()
        defer { lock.unlock() }

        if migrated.contains(username) {
            return
        }

        instance.migrateAuthKey(for: username)
        migrated.insert(username)
    }
}
