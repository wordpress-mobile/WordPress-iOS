import Foundation

public struct SocialKeyringAccount: Identifiable, Hashable, Sendable {
    /// Composite ID combining the keyring id and the external user id (or the
    /// keyring's primary external_ID when `externalUserID` is nil). Stable
    /// across fetches as long as the backend identifiers don't change.
    public let id: String
    public let name: String
    public let profilePictureURL: URL?
    public let keyring: SocialKeyringConnection
    /// Nil when the row represents the keyring's primary external account.
    public let externalUserID: String?

    public init(
        id: String,
        name: String,
        profilePictureURL: URL?,
        keyring: SocialKeyringConnection,
        externalUserID: String?
    ) {
        self.id = id
        self.name = name
        self.profilePictureURL = profilePictureURL
        self.keyring = keyring
        self.externalUserID = externalUserID
    }

    /// The external account ID used to match against existing
    /// `SocialConnection.externalID` values.
    public var externalIDForMatching: String {
        externalUserID ?? keyring.externalID
    }

    /// Flattens a list of keyrings into one account row per (keyring,
    /// external user) pair. Every keyring yields at least the primary row.
    public static func flatten(_ keyrings: [SocialKeyringConnection]) -> [SocialKeyringAccount] {
        keyrings.flatMap { keyring -> [SocialKeyringAccount] in
            // The `primary:` and `user:` discriminators keep IDs unique even
            // when a keyring's externalID happens to equal an additional
            // user's id.
            let primary = SocialKeyringAccount(
                id: "\(keyring.id):primary:\(keyring.externalID)",
                name: keyring.externalDisplay,
                profilePictureURL: keyring.externalProfilePictureURL,
                keyring: keyring,
                externalUserID: nil
            )
            let additional = keyring.additionalExternalUsers.map { user in
                SocialKeyringAccount(
                    id: "\(keyring.id):user:\(user.id)",
                    name: user.name,
                    profilePictureURL: user.profilePictureURL,
                    keyring: keyring,
                    externalUserID: user.id
                )
            }
            return [primary] + additional
        }
    }
}
