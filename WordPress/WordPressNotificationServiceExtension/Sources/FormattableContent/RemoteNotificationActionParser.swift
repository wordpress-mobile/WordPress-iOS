import Foundation

/// This class is analagous to `NotificationActionParser`, with extension-specific behavior.
class RemoteNotificationActionParser: FormattableContentActionParser {
    func parse(_ dictionary: [String : AnyObject]?) -> [FormattableContentAction] {
        return []
    }
}
