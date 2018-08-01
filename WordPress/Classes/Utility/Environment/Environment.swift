
import Foundation

/// A collection of global variables and singletons that the app wants access to.
///
struct Environment {

    // MARK: - Globals

    /// A type that helps tracking whether or not a user should be prompted for an app review
    let appRatingUtility: AppRatingUtilityType

    /// A type to create derived context, save context, etc...
    let contextManagerType: ContextManagerType.Type

    /// The mainContext that has concurrency type NSMainQueueConcurrencyType and should be used
    /// for UI elements and fetched results controllers.
    var mainContext: NSManagedObjectContext {
        return contextManagerType.shared.mainContext
    }

    // MARK: - Static current environment implementation

    /// The current environment. Use this to access the app globals.
    ///
    static private(set) var current = Environment()

    // MARK: - Initialization

    private init(
        appRatingUtility: AppRatingUtilityType = AppRatingUtility.shared,
        contextManagerType: ContextManagerType.Type = ContextManager.self) {

        self.appRatingUtility = appRatingUtility
        self.contextManagerType = contextManagerType
    }
}

extension Environment {
    /// Creates a new Environment, changing just a subset of the current global dependencies.
    ///
    @discardableResult
    static func replaceEnvironment(
        appRatingUtility: AppRatingUtilityType = Environment.current.appRatingUtility,
        contextManagerType: ContextManagerType.Type = Environment.current.contextManagerType) -> Environment {

        current = Environment(
            appRatingUtility: appRatingUtility,
            contextManagerType: contextManagerType
        )
        return current
    }
}
