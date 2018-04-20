import Foundation
import WordPressShared

// MARK: - Authentication Flow Event. Useful to relay internal Auth events over to activity trackers.
//
extension WordPressAuthenticator {

    /// Tracks the specified event.
    ///
    @objc
    public static func track(_ event: WPAnalyticsStat) {
        WordPressAuthenticator.shared.delegate?.track(event: event)
    }

    /// Tracks the specified event, with the specified properties.
    ///
    @objc
    public static func track(_ event: WPAnalyticsStat, properties: [AnyHashable: Any]) {
        WordPressAuthenticator.shared.delegate?.track(event: event, properties: properties)
    }

    /// Tracks the specified event, with the associated Error.
    ///
    /// Note: Ideally speaking... `Error` is not optional. *However* this method is to be used in the ObjC realm, where not everything
    /// has it's nullability specifier set. We're just covering unexpected scenarios.
    ///
    @objc
    public static func track(_ event: WPAnalyticsStat, error: Error?) {
        guard let error = error else {
            track(event)
            return
        }

        WordPressAuthenticator.shared.delegate?.track(event: event, error: error)
    }
}
