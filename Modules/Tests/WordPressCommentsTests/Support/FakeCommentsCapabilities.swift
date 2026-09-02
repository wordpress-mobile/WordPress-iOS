@testable import WordPressComments

@MainActor
final class FakeCommentsCapabilities: CommentsCapabilitiesProtocol {
    var canModerate = true
    var error: Error?
    private(set) var invocations = 0

    func canModerateComments() async throws -> Bool {
        invocations += 1
        if let error { throw error }
        return canModerate
    }
}
