import Foundation
import CryptoKit

public struct SupportUser: Sendable, Codable {
    public let userId: UInt64
    public let username: String
    public let email: String
    public let permissions: [SupportUserPermission]
    public let avatarUrl: URL

    public init(
        userId: UInt64,
        username: String,
        email: String,
        permissions: [SupportUserPermission] = [],
        avatarUrl: URL? = nil
    ) {
        self.userId = userId
        self.username = username
        self.email = email
        self.permissions = permissions

        if let avatarUrl {
            self.avatarUrl = avatarUrl
        } else {
            let data = Data(email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().utf8)
            let hash = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
            self.avatarUrl = URL(string: "https://gravatar.com/avatar/\(hash)")!
        }
    }
}
