import WordPressCore

protocol CommentsCapabilitiesProtocol: Sendable {
    /// Whether the current user can moderate comments. Throws when the lookup
    /// fails, so a caller can decide whether to cache the answer.
    func canModerateComments() async throws -> Bool
}

struct CommentsCapabilities: CommentsCapabilitiesProtocol {
    let client: WordPressClient

    func canModerateComments() async throws -> Bool {
        try await client.currentUserCan(.moderateComments)
    }
}
