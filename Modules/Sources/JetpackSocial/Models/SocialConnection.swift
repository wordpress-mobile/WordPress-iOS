import Foundation
import WordPressAPI

public struct SocialConnection: Identifiable, Hashable, Sendable {
    public var id: String
    /// The keyring (OAuth token) ID, shared by every connection backed by the
    /// same external login. Carried because legacy `_wpas_skip_<keyringID>`
    /// post meta rows are keyed by it and the backend still honors them at
    /// publish time. Maps from the v2 payload's deprecated `id` field, the
    /// only place the v2 API exposes this identifier.
    public var keyringConnectionID: String?
    public var externalID: String
    public var serviceName: String
    public var serviceLabel: String
    public var displayName: String
    public var externalHandle: String?
    public var profileLink: URL?
    public var profilePictureURL: URL?
    public var isShared: Bool
    public var status: ConnectionStatus

    public init(
        id: String,
        keyringConnectionID: String? = nil,
        externalID: String,
        serviceName: String,
        serviceLabel: String,
        displayName: String,
        externalHandle: String?,
        profileLink: URL?,
        profilePictureURL: URL?,
        isShared: Bool,
        status: ConnectionStatus
    ) {
        self.id = id
        self.keyringConnectionID = keyringConnectionID
        self.externalID = externalID
        self.serviceName = serviceName
        self.serviceLabel = serviceLabel
        self.displayName = displayName
        self.externalHandle = externalHandle
        self.profileLink = profileLink
        self.profilePictureURL = profilePictureURL
        self.isShared = isShared
        self.status = status
    }

    init(from wire: PublicizeConnectionResponse) {
        // Some social services return an empty `display_name` for connections
        // that only carry a handle (e.g., a Mastodon profile without a set
        // name). Mirror the legacy v1.1 fallback by surfacing the handle so
        // the row isn't blank.
        let externalHandle: String? = wire.externalHandle.flatMap { $0.nonEmpty }
        let displayName: String = wire.displayName.nonEmpty ?? externalHandle ?? wire.displayName
        self.init(
            id: wire.connectionId,
            keyringConnectionID: wire.id.nonEmpty,
            externalID: wire.externalId,
            serviceName: wire.serviceName,
            serviceLabel: wire.serviceLabel,
            displayName: displayName,
            externalHandle: externalHandle,
            profileLink: wire.profileLink.nonEmpty.flatMap(URL.init(string:)),
            profilePictureURL: wire.profilePicture.nonEmpty.flatMap(URL.init(string:)),
            isShared: wire.shared,
            status: ConnectionStatus(wireString: wire.status)
        )
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
