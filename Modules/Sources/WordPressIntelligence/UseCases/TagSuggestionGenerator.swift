import Foundation
import FoundationModels
import WordPressShared

/// Tag suggestion for WordPress posts.
///
/// Generates relevant tags based on post content and existing site tags,
/// matching the language and formatting pattern of existing tags.
@available(iOS 26, *)
public struct TagSuggestionGenerator {
    public var options: GenerationOptions

    public init(options: GenerationOptions = GenerationOptions(temperature: 0.2)) {
        self.options = options
    }

    /// Generates tags for a WordPress post.
    public func generate(post: String, siteTags: [String] = [], postTags: [String] = []) async throws -> [String] {
        let startTime = CFAbsoluteTimeGetCurrent()

        let response = try await makeSession().respond(
            to: makePrompt(post: post, siteTags: siteTags, postTags: postTags),
            generating: Result.self,
            options: options
        )

        WPLogInfo("TagSuggestion executed in \((CFAbsoluteTimeGetCurrent() - startTime) * 1000) ms")

        let existingPostTags = Set(postTags)
        return response.content.tags
            .deduplicated()
            .filter { !existingPostTags.contains($0) }
    }

    /// Creates a language model session configured for tag suggestion.
    public func makeSession() -> LanguageModelSession {
        LanguageModelSession(
            model: .init(guardrails: .permissiveContentTransformations),
            instructions: Self.instructions
        )
    }

    /// Instructions for the language model session.
    public static var instructions: String {
        """
        You are helping a WordPress user add tags to a post or a page.

        **Parameters**
        - POST_CONTENT: contents of the post (HTML or plain text)
        - SITE_TAGS: case-sensitive comma-separated list of the existing tags used elsewhere on the site (not always relevant to the post)
        - EXISTING_POST_TAGS: tags already added to the post

        \(IntelligenceService.makeLocaleInstructions())

        **Steps**
        - 1. Identify the specific formatting pattern used (e.g., lowercase with underscores, capitalized words with spaces, etc)
        - 2. Identify the language used in SITE_TAGS and POST_CONTENT
        - 3. Generate a list of relevant suggested tags based on POST_CONTENT and SITE_TAGS relevant to the content.

        **Requirements**
        - You MUST generate tags in the same language as SITE_TAGS and POST_CONTENT
        - Tags MUST match the formatting pattern and language of existing tags
        - Do not include any tags from EXISTING_POST_TAGS
        - If there are no relevant suggestions, returns an empty list
        - Do not produce any output other than the final list of tags
        """
    }

    /// Creates a prompt for tag suggestion with the given parameters.
    public func makePrompt(post: String, siteTags: [String], postTags: [String]) -> String {
        // Limit siteTags and content size to respect context window
        let siteTags = siteTags.prefix(50)
        let post = IntelligenceService.extractRelevantText(from: post)

        return """
        Suggest tags for a post.

        POST_CONTENT: '''
        \(post)
        '''

        SITE_TAGS: '\(siteTags.joined(separator: ", "))'

        EXISTING_POST_TAGS: '\(postTags.joined(separator: ", "))'
        """
    }

    /// Prompt for generating additional tag suggestions.
    public static var loadMorePrompt: String {
        "Generate additional relevant tags following the same format and language requirements"
    }

    // MARK: - Result Type

    @Generable
    public struct Result {
        @Guide(description: "Newly generated tags following the identified format", .count(5...10))
        public var tags: [String]
    }
}

private extension Array where Element: Hashable {
    func deduplicated() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
