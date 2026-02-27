import Foundation
import WordPressKit

/// - warning: Soft-deprecated.
public struct AppEnvironment {

    // MARK: - Globals

    /// A type to create derived context, save context, etc...
    public let contextManager: ContextManager

    /// The base url to use for WP.com api requests
    public let wordPressComApiBase: URL

    /// The mainContext that has concurrency type NSMainQueueConcurrencyType and should be used
    /// for UI elements and fetched results controllers.
    public var mainContext: NSManagedObjectContext {
        return contextManager.mainContext
    }

    // MARK: - Static current environment implementation

    /// The current environment. Use this to access the app globals.
    ///
    public static private(set) var current = AppEnvironment()

    // MARK: - Initialization

    private init(
        contextManager: ContextManager = ContextManager.shared,
        wordPressComApiBase: URL = WordPressComRestApi.apiBaseURL) {

        self.contextManager = contextManager
        self.wordPressComApiBase = wordPressComApiBase
    }
}

extension AppEnvironment {
    /// Creates a new Environment, changing just a subset of the current global dependencies.
    ///
    @discardableResult
    public static func replaceEnvironment(
        contextManager: ContextManager = AppEnvironment.current.contextManager,
        wordPressComApiBase: URL = AppEnvironment.current.wordPressComApiBase) -> AppEnvironment {

        current = AppEnvironment(
            contextManager: contextManager,
            wordPressComApiBase: wordPressComApiBase
        )
        return current
    }
}
