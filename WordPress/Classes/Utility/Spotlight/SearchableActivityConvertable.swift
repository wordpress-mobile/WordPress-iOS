import CoreSpotlight
import Intents
import MobileCoreServices

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

extension WPActivityType {
    var suggestedInvocationPhrase: String {
        switch self {
        case .siteList:
            return NSLocalizedString("My Sites in WordPress", comment: "Siri Suggestion to open My Sites")
        case .siteDetails:
            return NSLocalizedString("WordPress Site Details", comment: "Siri Suggestion to open My Sites")
        case .reader:
            return NSLocalizedString("WordPress Reader", comment: "Siri Suggestion to open My Sites")
        case .me:
            return NSLocalizedString("WordPress Profile", comment: "Siri Suggestion to open Me tab")
        case .appSettings:
            return NSLocalizedString("WordPress App Settings", comment: "Siri Suggestion to open App Settings")
        case .notificationSettings:
            return NSLocalizedString("WordPress Notification Settings", comment: "Siri Suggestion to open Notification Settings")
        case .support:
            return NSLocalizedString("WordPress Help", comment: "Siri Suggestion to open Support")
        case .notifications:
            return NSLocalizedString("WordPress Notifications", comment: "Siri Suggestion to open Notifications")
        }
    }
}

/// NSUserActivity userInfo keys
///
enum WPActivityUserInfoKeys: String {
    case siteId = "siteid"
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

    /// A dictionary containing state information related to this indexed activity.
    ///
    @objc optional var activityUserInfo: [String: String]? {get}

    /// Activity description
    ///
    @objc optional var activityDescription: String? {get}
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

        if let activityUserInfo = activityUserInfo {
            activity.userInfo = activityUserInfo
            activity.requiredUserInfoKeys = Set([WPActivityUserInfoKeys.siteId.rawValue])
        }

        if let activityDescription = activityDescription {
            let contentAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
            contentAttributeSet.contentDescription = activityDescription
            contentAttributeSet.contentCreationDate = nil // Set this to nil so it doesn't display in spotlight
            activity.contentAttributeSet = contentAttributeSet
        }

        activity.isEligibleForSearch = true
        activity.isEligibleForHandoff = false

        if #available(iOS 12.0, *) {
            activity.isEligibleForPrediction = true

            if let wpActivityType = WPActivityType(rawValue: activityType) {
                activity.suggestedInvocationPhrase = wpActivityType.suggestedInvocationPhrase
            }
        }

        // Set the UIViewController's userActivity property, which is defined in UIResponder. Doing this allows
        // UIKit to automagically manage this user activity (e.g. making it current when needed)
        userActivity = activity
    }
}
