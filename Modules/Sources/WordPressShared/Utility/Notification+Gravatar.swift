import Foundation

public enum GravatarQEAvatarUpdateNotificationKeys: String {
    case email
}

public extension NSNotification.Name {
    /// Gravatar Quick Editor updated the avatar
    static let GravatarQEAvatarUpdateNotification = NSNotification.Name(rawValue: "GravatarQEAvatarUpdateNotification")
}

extension Foundation.Notification {
    public func userInfoHasEmail(_ email: String) -> Bool {
        guard let userInfo,
              let notificationEmail = userInfo[GravatarQEAvatarUpdateNotificationKeys.email.rawValue] as? String else {
                  return false
              }
        return email == notificationEmail
    }
}
