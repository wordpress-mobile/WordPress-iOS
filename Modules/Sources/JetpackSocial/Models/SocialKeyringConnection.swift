import Foundation
import WordPressAPI

public struct SocialKeyringConnection: Identifiable, Hashable, Sendable {
    public let id: Int64
    public let service: String
    public let externalID: String
    public let externalName: String
    public let externalDisplay: String
    public let externalProfilePictureURL: URL?
    public let additionalExternalUsers: [AdditionalExternalUser]
    public let status: ConnectionStatus

    public init(
        id: Int64,
        service: String,
        externalID: String,
        externalName: String,
        externalDisplay: String,
        externalProfilePictureURL: URL?,
        additionalExternalUsers: [AdditionalExternalUser],
        status: ConnectionStatus
    ) {
        self.id = id
        self.service = service
        self.externalID = externalID
        self.externalName = externalName
        self.externalDisplay = externalDisplay
        self.externalProfilePictureURL = externalProfilePictureURL
        self.additionalExternalUsers = additionalExternalUsers
        self.status = status
    }

    init(from wire: KeyringConnectionResponse) {
        // Some keyrings come back with an empty `external_display`. Direct
        // port of the legacy v1.1 fallback in SharingServiceRemote: use
        // `external_name` so the picker doesn't show a blank account.
        let externalDisplay = wire.externalDisplay.isEmpty ? wire.externalName : wire.externalDisplay
        self.init(
            id: wire.id,
            service: wire.service,
            externalID: wire.externalId,
            externalName: wire.externalName,
            externalDisplay: externalDisplay,
            externalProfilePictureURL: wire.externalProfilePicture.flatMap(URL.init(string:)),
            additionalExternalUsers: wire.additionalExternalUsers.map(AdditionalExternalUser.init(from:)),
            status: ConnectionStatus(wireString: wire.status)
        )
    }
}
