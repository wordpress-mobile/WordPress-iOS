
/// A global instance of Environment that defines the current state of global objects that the app wants access to.
///
struct AppEnvironment {

    /// The current environment
    ///
    static var current: Environment {
        return _current ?? replaceEnvironment()
    }

    private static var _current: Environment?

    private init() {
    }

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
