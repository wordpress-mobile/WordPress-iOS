import Foundation

/// This class is analagous to `NotificationActionParser`, with extension-specific behavior.
/// For the time being, it is essentially a no-op to appease `FormattableContent`.
///
class RemoteNotificationActionParser: FormattableContentActionParser {
    func parse(_ dictionary: [String: AnyObject]?) -> [FormattableContentAction] {
        return []
    }
}
