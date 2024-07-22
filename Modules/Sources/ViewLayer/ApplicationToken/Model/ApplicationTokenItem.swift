import SwiftUI
import Network

public struct ApplicationTokenItem: Identifiable {
    public var id: String { uuid.uuidString }

    public let name: String
    public let uuid: UUID

    public let appId: String

    public let createdAt: Date
    public let lastUsed: Date?
    public let lastIpAddress: String?

    public init(name: String, uuid: UUID, appId: String, createdAt: Date, lastUsed: Date?, lastIpAddress: String?) {
        self.name = name
        self.uuid = uuid
        self.appId = appId
        self.createdAt = createdAt
        self.lastUsed = lastUsed
        self.lastIpAddress = lastIpAddress
    }
}

package extension ApplicationTokenItem {
    static let bobToken = ApplicationTokenItem(name: "Bob's iPad Mini", uuid: UUID(), appId: "1234", createdAt: .now, lastUsed: .now.advanced(by: -10_000), lastIpAddress: IPv4Address.any.debugDescription)

    static let aliceToken = ApplicationTokenItem(name: "Alice's super fast and tiny tablet with keyboard", uuid: UUID(), appId: "1234", createdAt: .now, lastUsed: nil, lastIpAddress: nil)
}

package extension [ApplicationTokenItem] {
    static let testTokens: [ApplicationTokenItem] = [
        .bobToken,
        .aliceToken
    ]
}
