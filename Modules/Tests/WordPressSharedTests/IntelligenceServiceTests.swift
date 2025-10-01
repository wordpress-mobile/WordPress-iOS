import Testing
@testable import WordPressShared

struct IntelligenceServiceTests {
    @available(iOS 26, *)
    @Test(.disabled("only for local testing"))
    func suggestTags() async throws {
        let tags = try await IntelligenceService()
            .suggestTags(
                post: IntelligenceUtilities.post,
                siteTags: ["cooking", "healthy-foods"]
            )
        print(tags)
    }
}
