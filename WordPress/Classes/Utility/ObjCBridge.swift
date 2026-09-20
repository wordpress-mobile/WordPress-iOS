import Foundation
import WordPressData

/// This class is a temporary bridge between Swift-only APIs in Keystone
/// and the remaining Objective-C classes that weren't replaced yet.
///
/// FIXME: Remove when remaining Objective-C usages are gone.
@objc public final class ObjCBridge: NSObject {
    @objc public class func showSigninForWPComFixingAuthToken() {
        WordPressAuthenticationManager.showSigninForWPComFixingAuthToken()
    }

    @objc public class func showSupportTableViewController() {
        SupportTableViewController().showFromTabBar()
    }

    @objc public class var isWordPress: Bool {
        AppConfiguration.isWordPress
    }

    @objc public class func incrementSignificantEvent() {
        AppRatingUtility.shared.incrementSignificantEvent()
    }

    /// The in-app Notifications bell state, for the legacy Objective-C tab bar.
    @objc @MainActor public class var hasNewNotificationActivity: Bool {
        NotificationActivityService.shared.hasNewActivity
    }

    /// Name of the notification posted when the bell state changes.
    @objc public class var notificationActivityDidChangeNotification: NSNotification.Name {
        .notificationActivityDidChange
    }
}
