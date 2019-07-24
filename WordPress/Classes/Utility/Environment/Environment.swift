
import Foundation
import WordPressKit

/// A collection of global variables and singletons that the app wants access to.
///
struct Environment {

    // MARK: - Globals

    /// A type that helps tracking whether or not a user should be prompted for an app review
    let appRatingUtility: AppRatingUtilityType

    /// A type to create derived context, save context, etc...
    let contextManager: ContextManagerType

    /// A simple database to store any kind of key-value pairs.
    let userDefaults: KeyValueDatabase

    /// The base url to use for WP.com api requests
    let wordPressComApiBase: String

    /// The mainContext that has concurrency type NSMainQueueConcurrencyType and should be used
    /// for UI elements and fetched results controllers.
    var mainContext: NSManagedObjectContext {
        return contextManager.mainContext
    }

    // MARK: - Static current environment implementation

    /// The current environment. Use this to access the app globals.
    ///
    static private(set) var current = Environment()

    // MARK: - Initialization

    // Defaults defined here will be normally unless explicitly overriden with a `replaceEnvironment()` call
    private init(
        appRatingUtility: AppRatingUtilityType = AppRatingUtility.shared,
        contextManager: ContextManagerType = ContextManager.shared,
        userDefaults: KeyValueDatabase = UserDefaults.standard,
        wordPressComApiBase: String = WordPressComRestApi.apiBaseURLString) {

        self.appRatingUtility = appRatingUtility
        self.contextManager = contextManager
        self.userDefaults = userDefaults
        self.wordPressComApiBase = wordPressComApiBase
    }
}

extension Environment {
    /// Creates a new Environment, changing just a subset of the current global dependencies.
    ///
    @discardableResult
    static func replaceEnvironment(
        appRatingUtility: AppRatingUtilityType = Environment.current.appRatingUtility,
        contextManager: ContextManagerType = Environment.current.contextManager,
        userDefaults: KeyValueDatabase = Environment.current.userDefaults,
        wordPressComApiBase: String = Environment.current.wordPressComApiBase) -> Environment {

        current = Environment(
            appRatingUtility: appRatingUtility,
            contextManager: contextManager,
            userDefaults: userDefaults,
            wordPressComApiBase: wordPressComApiBase
        )
        return current
    }
}
