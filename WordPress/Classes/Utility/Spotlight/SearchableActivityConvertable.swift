/// Custom NSUSerActivity types for the WPiOS. Primarily used for navigation points.
///
enum WPActivityType: String {
    case siteList               = "org.wordpress.mysites"
    case siteDetails            = "org.wordpress.mysites.details"
    case reader                 = "org.wordpress.reader"
    case me                     = "org.wordpress.me"
    case appSettings            = "org.wordpress.me.appsettings"
    case notificationSettings   = "org.wordpress.me.notificationsettings"
    case support                = "org.wordpress.me.support"
    case notifications          = "org.wordpress.notifications"
}

@objc protocol SearchableActivityConvertable {
    /// Type name used to uniquly indentify this activity.
    ///
    @objc var activityType: String {get}

    /// Activity title to be displayed in spotlight search.
    ///
    @objc var activityTitle: String {get}

    // MARK: Optional Vars

    /// A set of localized keywords that can help users find the activity in search results.
    ///
    @objc optional var activityKeywords: Set<String>? {get}

    /// The date after which the activity is no longer eligible for indexing. If not set,
    /// the expiration date will default to one week from the current date.
    ///
    @objc optional var activityExpirationDate: Date? {get}
}

extension SearchableActivityConvertable where Self: UIViewController {
    internal func registerUserActivity() {
        let activity = NSUserActivity(activityType: activityType)
        activity.title = activityTitle

        if let keywords = activityKeywords as? Set<String>, !keywords.isEmpty {
            activity.keywords = keywords
        }

        if let expirationDate = activityExpirationDate {
            activity.expirationDate = expirationDate
        } else {
            let oneWeekFromNow = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
            activity.expirationDate = oneWeekFromNow
        }

        activity.isEligibleForSearch = true
        activity.isEligibleForHandoff = false

        // Set the userActivity property of UIResponder
        userActivity = activity
    }
}
