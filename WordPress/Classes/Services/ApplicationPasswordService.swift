import Foundation
import WordPressAPI
import WordPressCore

@objc class ApplicationPasswordService: NSObject {

    private let apiClient: WordPressClient
    private var currentUserId: UserId?
    private var currentApplicationPasswordUUID: String?

    init(api: WordPressClient, currentUserId: Int? = nil) {
        self.apiClient = api
        self.currentUserId = currentUserId.flatMap(UserId.init)
    }

    private func fetchTokens(forUserId userId: UserId) async throws -> [ApplicationPasswordWithEditContext] {
        try await apiClient.api.applicationPasswords.listWithEditContext(userId: userId).data
    }
}

extension ApplicationPasswordService: ApplicationTokenListDataProvider {
    func loadApplicationTokens() async throws -> [ApplicationTokenItem] {
        let userId: UserId
        if let currentUserId {
            userId = currentUserId
        } else {
            userId = try await apiClient.api.users.retrieveMeWithViewContext().data.id
            currentUserId = userId
        }

        if self.currentApplicationPasswordUUID == nil {
            self.currentApplicationPasswordUUID = try? await apiClient.api.applicationPasswords.retrieveCurrentWithViewContext().data.uuid.uuid
        }

        return try await fetchTokens(forUserId: userId)
            .compactMap { token -> ApplicationTokenItem? in
                guard var item = ApplicationTokenItem(token) else { return nil }

                if let current = self.currentApplicationPasswordUUID {
                    item.isCurrent = current.compare(item.uuid.uuidString, options: .caseInsensitive) == .orderedSame
                }

                return item
            }
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
