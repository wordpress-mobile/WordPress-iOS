import WordPressCore

protocol CommentsCapabilitiesProtocol: Sendable {
    /// Whether the current user can moderate comments. Resolved once per
    /// detail screen; false also when the lookup fails, which degrades the
    /// screen to read-only (view-context fetch, no author email or IP).
    func canModerateComments() async -> Bool
}

struct CommentsCapabilities: CommentsCapabilitiesProtocol {
    let client: WordPressClient

    func canModerateComments() async -> Bool {
        // A failed current-user request must not block a readable
        // view-context detail screen.
        (try? await client.currentUserCan(.moderateComments)) ?? false
    }
}
