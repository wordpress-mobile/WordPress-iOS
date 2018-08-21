import Foundation
import UserNotifications

// MARK: - Describes userInfo keys within the APNS payload

private extension CodingUserInfoKey {
    static let alert = CodingUserInfoKey(rawValue: "alert")!
    static let aps = CodingUserInfoKey(rawValue: "aps")!
}

// MARK: - Supports standard APNS notification content

extension UNNotificationContent {
    /// the value of the `aps` node from the APNS payload if it exists; `nil` otherwise
    private var aps: NSDictionary? {
        return userInfo[CodingUserInfoKey.aps.rawValue] as? NSDictionary
    }

    /// the value of the `alert` field from the `aps` portion of the APNS payload if it exists; `nil` otherwise
    var apsAlert: String? {
        return aps?[CodingUserInfoKey.alert.rawValue] as? String
    }
}

// MARK: - Describes userInfo keys used to exchange data between extension types

private extension CodingUserInfoKey {
    static let noteIdentifier = CodingUserInfoKey(rawValue: "note_id")!
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
}
