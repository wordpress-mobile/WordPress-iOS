@testable import WordPressComments

@MainActor
final class FakeCommentsCapabilities: CommentsCapabilitiesProtocol {
    var canModerate = true

    func canModerateComments() async -> Bool {
        canModerate
    }
}
