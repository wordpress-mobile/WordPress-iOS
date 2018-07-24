
import Foundation

/// A collection of global variables and singletons that the app wants access to.
///
struct Environment {

    // MARK: - Globals

    /// A type that helps tracking whether or not a user should be prompted for an app review
    let appRatingUtility: AppRatingUtilityType

    /// The main Core Data context
    let mainContext: NSManagedObjectContext

    // MARK: - Static current environment implementation

    /// The current environment
    ///
    static var current: Environment {
        return _current ?? replaceEnvironment()
    }

    private static var _current: Environment?

    // MARK: - Initialization

    private init(
        appRatingUtility: AppRatingUtilityType = AppRatingUtility.shared,
        mainContext: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {

        self.appRatingUtility = appRatingUtility
        self.mainContext = mainContext
    }
}

extension Environment {
    /// Creates a new Environment, changin just a subset of the current global dependencies.
    ///
    @discardableResult
    static func replaceEnvironment(
        appRatingUtility: AppRatingUtilityType = AppRatingUtility.shared,
        mainContext: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) -> Environment {

        let current = Environment(
            appRatingUtility: appRatingUtility,
            mainContext: mainContext
        )
        _current = current
        return current
    }
}
