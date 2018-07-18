
import Foundation

/// A collection of global variables and singletons that the app wants access to.
///
struct Environment {
    /// A type that helps tracking whether or not a user should be prompted for an app review
    let appRatingUtility: AppRatingUtilityType

    /// The main Core Data context
    let mainContext: NSManagedObjectContext

    init(
        appRatingUtility: AppRatingUtilityType = AppRatingUtility.shared,
        mainContext: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {

        self.appRatingUtility = appRatingUtility
        self.mainContext = mainContext
    }
}
