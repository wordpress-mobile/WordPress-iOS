import Foundation
import UserNotifications

// MARK: - RichNotificationViewModel definition

/// This class serves as the medium of exchange between the service & content extensions.
struct RichNotificationViewModel {

    /// The body of a rich notification.
    var attributedBody: NSAttributedString?

    /// The subject of a rich notification.
    var attributedSubject: NSAttributedString?

    /// The URL string of the notification "sender's" Gravatar; `nil` otherwise
    var gravatarURLString: String?

    /// The "noticon" event label corresponding to the notification type; `nil` otherwise
    var noticon: String?
}

// MARK: - Describes userInfo keys used to exchange data between extension types

private extension CodingUserInfoKey {
    static let attributedBody = CodingUserInfoKey(rawValue: "attributedBody")!
    static let attributedSubject = CodingUserInfoKey(rawValue: "attributedSubject")!
    static let gravatarURLString = CodingUserInfoKey(rawValue: "gravatarURLString")!
    static let noticonText = CodingUserInfoKey(rawValue: "noticon")!
}

// MARK: - Class behavior

private extension RichNotificationViewModel {
    static func decode(from notificationContent: UNNotificationContent, withKey key: CodingUserInfoKey) -> NSAttributedString? {
        guard let attributedData = notificationContent.userInfo[key.rawValue] as? Data else { return nil }

        let decodingAttributes: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        return try? NSAttributedString(data: attributedData, options: decodingAttributes, documentAttributes: nil)
    }

    static func encode(_ value: NSAttributedString?, to notificationContent: UNMutableNotificationContent, withKey key: CodingUserInfoKey) {
        guard let validValue = value else { return }

        let range = NSRange(location: 0, length: validValue.length)
        let encodingAttributes: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html
        ]

        if let attributedData = try? validValue.data(from: range, documentAttributes: encodingAttributes) {
            notificationContent.userInfo[key.rawValue] = attributedData
        }
    }
}

// MARK: - UNNotificationContent encoding & decoding

extension RichNotificationViewModel {
    /// Instantiates a RichNotificationViewModel by decoding the contents of `userInfo` for a given notification.
    ///
    /// - Parameter notificationContent: the notification content with which this should be instantiated
    init(notificationContent: UNNotificationContent) {
        let decodedBody = RichNotificationViewModel.decode(from: notificationContent, withKey: CodingUserInfoKey.attributedBody)
        let decodedSubject = RichNotificationViewModel.decode(from: notificationContent, withKey: CodingUserInfoKey.attributedSubject)
        let decodedGravatarURLString = notificationContent.userInfo[CodingUserInfoKey.gravatarURLString.rawValue] as? String
        let decodedNoticon = notificationContent.userInfo[CodingUserInfoKey.noticonText.rawValue] as? String

        self.init(
            attributedBody: decodedBody?.copy() as? NSAttributedString,
            attributedSubject: decodedSubject?.copy() as? NSAttributedString,
            gravatarURLString: decodedGravatarURLString,
            noticon: decodedNoticon
        )
    }

    /// Writes the contents of a given `RemoteNotification` to `userInfo`.
    ///
    /// - Parameter notificationContent: the notification of interest
    func encodeToUserInfo(notificationContent: UNMutableNotificationContent) {
        RichNotificationViewModel.encode(attributedBody, to: notificationContent, withKey: CodingUserInfoKey.attributedBody)
        RichNotificationViewModel.encode(attributedSubject, to: notificationContent, withKey: CodingUserInfoKey.attributedSubject)
        notificationContent.userInfo[CodingUserInfoKey.gravatarURLString.rawValue] = gravatarURLString
        notificationContent.userInfo[CodingUserInfoKey.noticonText.rawValue] = noticon
    }
}
