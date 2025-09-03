import Foundation

public struct RemoteInviteLink {
    public let inviteKey: String
    public let role: String
    public let isPending: Bool
    public let inviteDate: Date
    public let groupInvite: Bool
    public let expiry: Int64
    public let link: String

    init(dict: [String: Any]) {
        var date = Date()
        if let inviteDate = dict["invite_date"] as? String,
           let formattedDate = ISO8601DateFormatter().date(from: inviteDate) {
            date = formattedDate
        }
        inviteKey = dict["invite_key"] as? String ?? ""
        role = dict["role"] as? String ?? ""
        isPending = dict["is_pending"] as? Bool ?? false
        inviteDate = date
        groupInvite = dict["is_group_invite"] as? Bool ?? false
        expiry = dict["expiry"] as? Int64 ?? 0
        link = dict["link"] as? String ?? ""
    }
}
