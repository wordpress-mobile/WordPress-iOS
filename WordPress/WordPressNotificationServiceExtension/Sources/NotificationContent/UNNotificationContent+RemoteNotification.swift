import Foundation
import UserNotifications

// MARK: - Describes userInfo keys within the APNS payload

private extension CodingUserInfoKey {
    static let title    = CodingUserInfoKey(rawValue: "title")!
    static let alert    = CodingUserInfoKey(rawValue: "alert")!
    static let aps      = CodingUserInfoKey(rawValue: "aps")!
}

// MARK: - Supports standard APNS notification content

extension UNNotificationContent {
    /// the value of the `aps` node from the APNS payload if it exists; `nil` otherwise
    private var aps: NSDictionary? {
        return userInfo[CodingUserInfoKey.aps.rawValue] as? NSDictionary
    }

    /// the value of the `alert` field from the `aps` portion of the APNS payload if it exists; `nil` otherwise
    var alertString: String? {
        // The APNSv1 system only allows string alerts
        if let alertString = aps?[CodingUserInfoKey.alert.rawValue] as? String {
            return alertString
        }

        // In v2, the alert can be an object
        let alertObject = aps?[CodingUserInfoKey.alert.rawValue] as? NSDictionary

        // If the `alert.title` property is present, we'll use it for this purpose
        if let alertTitle = alertObject?[CodingUserInfoKey.title.rawValue] as? String {
            return alertTitle
        }

        return nil
    }
}

// MARK: - Describes userInfo keys used to exchange data between extension types

private extension CodingUserInfoKey {
    static let noteIdentifier   = CodingUserInfoKey(rawValue: "note_id")!
    static let type             = CodingUserInfoKey(rawValue: "type")!
}

// MARK: - Supports APNS notification related to `RemoteNotification`

extension UNNotificationContent {
    /// the value of the `note_id` from the APNS payload if it exists; `nil` otherwise
    var noteID: String? {
        guard let rawNoteId = userInfo[CodingUserInfoKey.noteIdentifier.rawValue] as? Int else {
            return nil
        }
        return String(rawNoteId)
    }

    /// the value of the `type` from the APNS payload if it exists; `nil` otherwise
    var type: String? {
        return userInfo[CodingUserInfoKey.type.rawValue] as? String
    }
}
