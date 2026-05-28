import BuildSettingsKit
import CoreData
import WordPressKit
import WordPressShared

@objc(WPAccount)
public class WPAccount: NSManagedObject {

    // MARK: - Core Data Properties

    @NSManaged public var userID: NSNumber?
    @NSManaged public var avatarURL: String?
    @NSManaged public var uuid: String?
    @NSManaged public var dateCreated: Date?
    @NSManaged public var email: String?
    @NSManaged public var displayName: String?
    @NSManaged public var emailVerified: NSNumber?
    @NSManaged public var primaryBlogID: NSNumber?
    @NSManaged public var blogs: Set<Blog>?
    @NSManaged public var defaultBlog: Blog?
    @NSManaged public var settings: ManagedAccountSettings?

    // MARK: - Non-Core-Data Stored Properties

    /// Important: Do not set this directly!
    ///
    /// It's reserved for Objective-C to Swift interoperability in the context of
    /// separating this model from the app target and will be removed at some point.
    @objc public var _private_wordPressComRestApi: WordPressComRestApi?

    private var cachedToken: String?

    lazy var keychain: any KeychainAccessible = KeychainUtils()
    lazy var keychainServiceName: String = BuildSettings.current.authKeychainServiceName
    lazy var keychainMigration: any AuthKeyMigrationProtocol = AuthKeyMigration()

    // MARK: - Core Data Generated Accessors

    @objc(addBlogsObject:)
    @NSManaged public func addBlogsObject(_ value: Blog)

    @objc(removeBlogsObject:)
    @NSManaged public func removeBlogsObject(_ value: Blog)

    @objc(addBlogs:)
    @NSManaged public func addBlogs(_ values: NSSet)

    @objc(removeBlogs:)
    @NSManaged public func removeBlogs(_ values: NSSet)

    public func addBlogs(_ values: Set<Blog>) {
        addBlogs(values as NSSet)
    }

    // MARK: - Custom Username Accessor

    /// The `username` property uses a custom setter to migrate the auth token
    /// in the keychain when the username changes.
    @objc public var username: String {
        get {
            willAccessValue(forKey: "username")
            let value = primitiveValue(forKey: "username") as? String ?? ""
            didAccessValue(forKey: "username")
            return value
        }
        set {
            let previousUsername = username
            let usernameChanged = previousUsername != newValue
            var authTokenValue: String?

            if usernameChanged {
                authTokenValue = authToken
                authToken = nil
            }

            willChangeValue(forKey: "username")
            setPrimitiveValue(newValue, forKey: "username")
            didChangeValue(forKey: "username")

            if usernameChanged {
                authToken = authTokenValue
            }
        }
    }

    // MARK: - Entity Name

    @objc public override class func entityName() -> String {
        return "Account"
    }

    // MARK: - Lifecycle

    public override func prepareForDeletion() {
        super.prepareForDeletion()

        // Only do these deletions in the primary context (no parent)
        if managedObjectContext?.concurrencyType == .mainQueueConcurrencyType {
            _private_wordPressComRestApi?.invalidateAndCancelTasks()
            _private_wordPressComRestApi = nil
            authToken = nil
        }
    }

    public override func didTurnIntoFault() {
        super.didTurnIntoFault()
        _private_wordPressComRestApi = nil
        cachedToken = nil
    }

    // MARK: - Auth Token (Keychain)

    /// The OAuth2 auth token for WordPress.com accounts
    @objc public var authToken: String? {
        get { _getAuthToken() }
        set { _setAuthToken(newValue) }
    }

    private func _getAuthToken() -> String? {
        if let cachedToken {
            return cachedToken
        }
        let token = try? Self.token(
            forUsername: username,
            serviceName: keychainServiceName,
            migration: keychainMigration,
            keychain: keychain
        )
        cachedToken = token
        return token
    }

    private func _setAuthToken(_ authToken: String?) {
        cachedToken = nil

        // Make sure to release any RestAPI alloc'ed, since it might have an invalid token
        _private_wordPressComRestApi = nil

        do {
            try keychain.setPassword(for: username, to: authToken, serviceName: keychainServiceName)
        } catch {
            WPLogError("Error while updating or deleting WordPressComOAuthKeychainServiceName token: %@", error.localizedDescription)
        }
    }

    public static func token(forUsername username: String) throws -> String {
        try token(
            forUsername: username,
            serviceName: BuildSettings.current.authKeychainServiceName,
            migration: AuthKeyMigration(),
            keychain: KeychainUtils()
        )
    }

    private static func token(
        forUsername username: String,
        serviceName: String,
        migration: any AuthKeyMigrationProtocol,
        keychain: any KeychainAccessible
    ) throws -> String {
        migration.migrateIfNeeded(username: username)

        do {
            return try keychain.getPassword(for: username, serviceName: serviceName)
        } catch {
            WPLogError("Error while retrieving WordPressComOAuthKeychainServiceName token: %@", error.localizedDescription)
            throw error
        }
    }
}
