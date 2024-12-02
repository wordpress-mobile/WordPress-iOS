import Foundation
import WordPressAPI

@objc class ApplicationPasswordService: NSObject {

    private let apiClient: WordPressClient
    private let currentUserId: Int

    init(api: WordPressClient, currentUserId: Int) {
        self.apiClient = api
        self.currentUserId = currentUserId
    }

    private func fetchTokens(forUserId userId: Int32) async throws -> [ApplicationPasswordWithEditContext] {
        try await apiClient.api.applicationPasswords.listWithEditContext(userId: userId).data
    }
}

extension ApplicationPasswordService: ApplicationTokenListDataProvider {
    func loadApplicationTokens() async throws -> [ApplicationTokenItem] {
        try await fetchTokens(forUserId: Int32(currentUserId))
            .compactMap(ApplicationTokenItem.init)
    }
}

extension ApplicationTokenItem {
    init?(_ rawToken: ApplicationPasswordWithEditContext) {
        guard
            let uuid = UUID(uuidString: rawToken.uuid.uuid),
            let createdAt = Date.fromWordPressDate(rawToken.created)
        else {
            return nil
        }

        let lastUsed = rawToken.lastUsed.flatMap(Date.fromWordPressDate(_:))

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
