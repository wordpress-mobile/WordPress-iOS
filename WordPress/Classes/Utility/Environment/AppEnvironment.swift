
import Foundation
import WordPressKit

/// A collection of global variables and singletons that the app wants access to.
///
struct AppEnvironment {

    // MARK: - Globals

    /// A type to create derived context, save context, etc...
    let contextManager: CoreDataStack

    /// The base url to use for WP.com api requests
    let wordPressComApiBase: URL

    /// The mainContext that has concurrency type NSMainQueueConcurrencyType and should be used
    /// for UI elements and fetched results controllers.
    var mainContext: NSManagedObjectContext {
        return contextManager.mainContext
    }

    // MARK: - Static current environment implementation

    /// The current environment. Use this to access the app globals.
    ///
    static private(set) var current = AppEnvironment()

    // MARK: - Initialization

    private init(
        contextManager: CoreDataStack = ContextManager.shared,
        wordPressComApiBase: URL = WordPressComRestApi.apiBaseURL) {

        self.contextManager = contextManager
        self.wordPressComApiBase = wordPressComApiBase
    }
}

extension AppEnvironment {
    /// Creates a new Environment, changing just a subset of the current global dependencies.
    ///
    @discardableResult
    static func replaceEnvironment(
        contextManager: CoreDataStack = AppEnvironment.current.contextManager,
        wordPressComApiBase: URL = AppEnvironment.current.wordPressComApiBase) -> AppEnvironment {

        current = AppEnvironment(
            contextManager: contextManager,
            wordPressComApiBase: wordPressComApiBase
        )
        return current
    }
}
