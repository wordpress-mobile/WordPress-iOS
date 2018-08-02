
import Foundation

/// A collection of global variables and singletons that the app wants access to.
///
struct Environment {

    // MARK: - Globals

    /// A type that helps tracking whether or not a user should be prompted for an app review
    let appRatingUtility: AppRatingUtilityType

    /// A type to create derived context, save context, etc...
    let contextManager: ContextManagerType

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

    private init(
        appRatingUtility: AppRatingUtilityType = AppRatingUtility.shared,
        contextManager: ContextManagerType = ContextManager.shared) {

        self.appRatingUtility = appRatingUtility
        self.contextManager = contextManager
    }
}

extension Environment {
    /// Creates a new Environment, changing just a subset of the current global dependencies.
    ///
    @discardableResult
    static func replaceEnvironment(
        appRatingUtility: AppRatingUtilityType = Environment.current.appRatingUtility,
        contextManager: ContextManagerType = Environment.current.contextManager) -> Environment {

        current = Environment(
            appRatingUtility: appRatingUtility,
            contextManager: contextManager
        )
        return current
    }
}
