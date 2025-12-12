import Testing
@testable import WordPressIntelligence

struct IntelligenceServiceTests {
    @available(iOS 26, *)
    @Test(.disabled("only for local testing"))
    func suggestTags() async throws {
        let tags = try await IntelligenceService()
            .suggestTags(
                post: ContentExtractor.post,
                siteTags: ["cooking", "healthy-foods"]
            )
        print(tags)
    }
}
