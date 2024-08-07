import Foundation
import WordPressAPI
import ViewLayer

struct ApplicationPasswordService {

    private let apiClient: WordPressClient

    init(api: WordPressClient) {
        self.apiClient = api
    }

    func fetchTokens(forUserId userId: Int32) async throws -> [ApplicationPasswordWithEditContext] {
        try await apiClient.api.applicationPasswords.listWithEditContext(userId: Int32())
    }
}

extension ApplicationPasswordService: ApplicationTokenListDataProvider {
    func loadApplicationTokens() async throws -> [ViewLayer.ApplicationTokenItem] {
        try await fetchTokens(forUserId: 1).compactMap(ApplicationTokenItem.init)
    }
}

extension ApplicationTokenItem {
    init?(_ rawToken: ApplicationPasswordWithEditContext) {
        guard
            let uuid = UUID(uuidString: rawToken.uuid.uuid),
            let createdAt = ISO8601DateFormatter().date(from: rawToken.created)
        else {
            return nil
        }

        var lastUsed: Date? = nil

        if let rawLastUsed = rawToken.lastUsed {
            lastUsed = ISO8601DateFormatter().date(from: rawLastUsed)
        }

        self = ApplicationTokenItem(
            name: rawToken.name,
            uuid: uuid,
            appId: rawToken.appId.appId,
            createdAt: createdAt,
            lastUsed: lastUsed,
            lastIpAddress: rawToken.lastIp?.value
        )
    }
}
