import Foundation
import WordPressAPI

public struct AdditionalExternalUser: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let profilePictureURL: URL?

    public init(id: String, name: String, description: String?, profilePictureURL: URL?) {
        self.id = id
        self.name = name
        self.description = description
        self.profilePictureURL = profilePictureURL
    }

    init(from wire: KeyringExternalUser) {
        self.init(
            id: wire.externalId,
            name: wire.externalName,
            description: wire.externalDescription,
            profilePictureURL: wire.externalProfilePicture.flatMap(URL.init(string:))
        )
    }
}
