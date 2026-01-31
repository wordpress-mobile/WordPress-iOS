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

        let prompt = await makePrompt(post: post, siteTags: siteTags, postTags: postTags)
        let response = try await makeSession().respond(
            to: prompt,
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
        - TARGET_LANGUAGE: the detected language code for tag generation (e.g., "en", "es", "fr", "ja") when available

        \(IntelligenceService.makeLocaleInstructions())

        **Steps**
        - 1. Identify the specific formatting pattern used (e.g., lowercase with underscores, capitalized words with spaces, etc)
        - 2. Generate a list of relevant suggested tags based on POST_CONTENT and SITE_TAGS relevant to the content.

        **CRITICAL Requirements**
        - ⚠️ LANGUAGE: Generate tags in the language specified by TARGET_LANGUAGE code if provided. If SITE_TAGS exist, match their language. Otherwise match POST_CONTENT language. NO translation. NO defaulting to English.
        - Tags MUST match the formatting pattern of existing SITE_TAGS (capitalization, separators, etc)
        - Do not include any tags from EXISTING_POST_TAGS
        - If there are no relevant suggestions, returns an empty list
        - Do not produce any output other than the final list of tags
        """
    }

    /// Creates a prompt for tag suggestion with the given parameters.
    ///
    /// This method handles content extraction and language detection automatically.
    /// Language is detected from site tags (if available) or post content, with site tags taking priority.
    ///
    /// - Parameters:
    ///   - post: The raw post content (may include HTML)
    ///   - siteTags: Existing tags from the site
    ///   - postTags: Tags already added to this post
    /// - Returns: Formatted prompt string ready for the language model
    public func makePrompt(post: String, siteTags: [String], postTags: [String]) async -> String {
        // Limit siteTags and content size to respect context window
        let siteTags = siteTags.prefix(50)
        let extractedPost = IntelligenceService.extractRelevantText(from: post)

        // Detect language: prioritize site tags language, fallback to post content
        let language: String? = {
            if !siteTags.isEmpty {
                let siteTagsText = siteTags.joined(separator: " ")
                if let tagLanguage = IntelligenceService.detectLanguage(from: siteTagsText) {
                    return tagLanguage
                }
            }
            return IntelligenceService.detectLanguage(from: extractedPost)
        }()

        let languageInstruction = language.map { "TARGET_LANGUAGE: \($0)\n\n" } ?? ""

        return """
        Suggest tags for a post.

        \(languageInstruction)POST_CONTENT: '''
        \(extractedPost)
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
