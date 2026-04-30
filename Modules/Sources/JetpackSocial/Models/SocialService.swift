import Foundation
import WordPressAPI

public struct SocialService: Identifiable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let description: String
    public let supportsAdditionalUsers: Bool
    public let isActive: Bool
    public let connectURL: URL?

    public init(
        id: String,
        label: String,
        description: String,
        supportsAdditionalUsers: Bool,
        isActive: Bool,
        connectURL: URL? = nil
    ) {
        self.id = id
        self.label = label
        self.description = description
        self.supportsAdditionalUsers = supportsAdditionalUsers
        self.isActive = isActive
        self.connectURL = connectURL
    }

    init(from wire: PublicizeServiceResponse) {
        self.init(
            id: wire.id,
            label: wire.label,
            description: wire.description,
            supportsAdditionalUsers: wire.supports.additionalUsers,
            isActive: wire.status == "ok",
            connectURL: wire.url.isEmpty ? nil : URL(string: wire.url)
        )
    }
}
