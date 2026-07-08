import Foundation
import UIKit
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

    @objc public class func trackBlazeEntryPointDisplayed(source: BlazeSource) {
        BlazeEventsTracker.trackEntryPointDisplayed(for: source)
    }

    @objc public class var isWordPress: Bool {
        AppConfiguration.isWordPress
    }

    @objc public class func incrementSignificantEvent() {
        AppRatingUtility.shared.incrementSignificantEvent()
    }

    @objc public class var unreadNotificationsCount: Int {
        ZendeskUtils.unreadNotificationsCount
    }
}
