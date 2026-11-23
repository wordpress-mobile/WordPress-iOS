import Foundation
import WordPressAPI
import WordPressCore
import WordPressData

@MainActor
@objc class ApplicationPasswordService: NSObject {

    private let apiClient: WordPressClient
    private var currentUserId: UserId?
    private let makeDeletionAPI: () throws -> WordPressAPI

    convenience init(api: WordPressClient, blog: Blog, currentUserId: Int? = nil) {
        let blogID = TaggedManagedObjectID(blog)
        self.init(
            api: api,
            currentUserId: currentUserId,
            makeDeletionAPI: {
                let site = try ContextManager.shared.performQuery { context in
                    try WordPressSite(blog: context.existingObject(with: blogID))
                }
                return try WordPressClient.applicationPasswordAPI(for: site)
            }
        )
    }

    init(api: WordPressClient, currentUserId: Int? = nil, makeDeletionAPI: @escaping () throws -> WordPressAPI) {
        self.apiClient = api
        self.makeDeletionAPI = makeDeletionAPI
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

        let currentUUID = try? await apiClient.api.applicationPasswords
            .retrieveCurrentWithViewContext().data.uuid.uuid
        let current = currentUUID.flatMap(UUID.init(uuidString:))

        return try await fetchTokens(forUserId: userId)
            .compactMap { token -> ApplicationTokenItem? in
                guard var item = ApplicationTokenItem(token) else { return nil }

                item.isCurrent = current == item.uuid
                item.canDelete = current != nil && !item.isCurrent

                return item
            }
    }
}

extension ApplicationPasswordService {
    func deleteApplicationToken(uuid: UUID) async throws {
        let api = try makeDeletionAPI()
        let userID = try await api.users.retrieveMeWithViewContext().data.id
        let identity = try await api.applicationPasswords.retrieveCurrentWithViewContext().data.uuid.uuid
        guard let current = UUID(uuidString: identity) else {
            throw ApplicationPasswordDeletionError.unknownCurrentPassword
        }
        guard current != uuid else {
            throw ApplicationPasswordDeletionError.currentPassword
        }

        do {
            // Core matches UUID strings exactly and stores them in lowercase.
            let response = try await api.applicationPasswords.delete(
                userId: userID,
                applicationPasswordUuid: .init(uuid: uuid.uuidString.lowercased())
            )
            guard response.data.deleted else {
                throw ApplicationPasswordDeletionError.deletionNotConfirmed
            }
        } catch let error as WpApiError {
            guard case let .WpError(code, _, status, _, _, _) = error,
                code == .ApplicationPasswordNotFound, status == 404
            else {
                throw error
            }
            // A retry after a lost response, or deletion elsewhere, has the same final state.
        }
    }
}

enum ApplicationPasswordDeletionError: LocalizedError {
    case currentPassword
    case unknownCurrentPassword
    case deletionNotConfirmed

    var errorDescription: String? {
        switch self {
        case .currentPassword:
            NSLocalizedString(
                "applicationPassword.revoke.current",
                value: "This application password is currently being used by the app and cannot be revoked here.",
                comment: "Explanation for protecting the current application password"
            )
        case .unknownCurrentPassword:
            NSLocalizedString(
                "applicationPassword.revoke.unknownCurrent",
                value:
                    "The app could not verify which application password it is using. Retry before revoking a password.",
                comment: "Explanation when the app cannot safely revoke an application password"
            )
        case .deletionNotConfirmed:
            NSLocalizedString(
                "applicationPassword.revoke.notConfirmed",
                value: "The site did not confirm that the application password was revoked. Please try again.",
                comment: "Error when a site does not confirm revocation"
            )
        }
    }
}

extension ApplicationTokenItem {
    /// Why this password cannot be deleted. Only meaningful when `canDelete` is false.
    var deletionBlocker: ApplicationPasswordDeletionError {
        isCurrent ? .currentPassword : .unknownCurrentPassword
    }

    init?(_ rawToken: ApplicationPasswordWithEditContext) {
        guard let uuid = UUID(uuidString: rawToken.uuid.uuid) else {
            return nil
        }

        // wordpress-rs 0.8.0 delivers these as parsed `Date`s, not strings.
        self = ApplicationTokenItem(
            name: rawToken.name,
            uuid: uuid,
            appId: rawToken.appId.appId,
            createdAt: rawToken.created,
            lastUsed: rawToken.lastUsed,
            lastIpAddress: rawToken.lastIp?.value
        )
    }
}
