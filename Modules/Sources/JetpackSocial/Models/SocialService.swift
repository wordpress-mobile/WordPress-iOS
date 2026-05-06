import Foundation
import WordPressAPI

public struct SocialService: Identifiable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let description: String
    public let supportsAdditionalUsers: Bool
    /// True for services like Facebook where Publicize can only target sub-accounts
    /// (Pages) and not the keyring's primary external account (the user's profile).
    /// `AccountConfirmationView` uses this to hide the primary row from the picker.
    public let additionalUsersOnly: Bool
    public let isActive: Bool
    public let connectURL: URL?

    public init(
        id: String,
        label: String,
        description: String,
        supportsAdditionalUsers: Bool,
        additionalUsersOnly: Bool,
        isActive: Bool,
        connectURL: URL? = nil
    ) {
        self.id = id
        self.label = label
        self.description = description
        self.supportsAdditionalUsers = supportsAdditionalUsers
        self.additionalUsersOnly = additionalUsersOnly
        self.isActive = isActive
        self.connectURL = connectURL
    }

    init(from wire: PublicizeServiceResponse) {
        self.init(
            id: wire.id,
            label: wire.label,
            description: wire.description,
            supportsAdditionalUsers: wire.supports.additionalUsers,
            additionalUsersOnly: wire.supports.additionalUsersOnly,
            isActive: wire.status == "ok",
            connectURL: wire.url.isEmpty ? nil : URL(string: wire.url)
        )
    }
}
