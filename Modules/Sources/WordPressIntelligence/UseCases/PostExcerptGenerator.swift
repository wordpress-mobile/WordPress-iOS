import Foundation
import FoundationModels

/// Excerpt generation for WordPress posts.
///
/// Generates multiple excerpt variations for blog posts with customizable
/// length and writing style. Supports session-based usage (for UI with continuity)
/// and one-shot generation (for tests and background tasks).
@available(iOS 26, *)
public struct PostExcerptGenerator {
    public var length: ContentLength
    public var style: WritingStyle
    public var options: GenerationOptions

    public init(
        length: ContentLength,
        style: WritingStyle,
        options: GenerationOptions = GenerationOptions(temperature: 0.7)
    ) {
        self.length = length
        self.style = style
        self.options = options
    }

    /// Generates excerpts with this configuration.
    public func generate(for content: String) async throws -> [String] {
        let content = IntelligenceService.extractRelevantText(from: content)
        let response = try await makeSession().respond(
            to: makePrompt(content: content),
            generating: Result.self,
            options: options
        )
        return response.content.excerpts
    }

    /// Creates a language model session configured for excerpt generation.
    public func makeSession() -> LanguageModelSession {
        LanguageModelSession(
            model: .init(guardrails: .permissiveContentTransformations),
            instructions: Self.instructions
        )
    }

    /// Instructions for the language model session.
    public static var instructions: String {
        """
        You are helping a WordPress user generate an excerpt for their post or page.

        **Prompt Parameters**
        - POST_CONTENT: contents of the post (HTML or plain text)
        - TARGET_LENGTH: MANDATORY sentence count (primary) and word count (secondary) for each excerpt
        - GENERATION_STYLE: the writing style to follow

        \(IntelligenceService.makeLocaleInstructions())

        **CRITICAL Requirements (MUST be followed exactly)**
        1. ⚠️ LANGUAGE: Generate excerpts in the SAME language as POST_CONTENT. NO translation. NO defaulting to English. Match input language EXACTLY.

        2. ⚠️ LENGTH: Each excerpt MUST match the TARGET_LENGTH specification.
           - PRIMARY: Match the sentence count (e.g., "1-2 sentences" means write 1 or 2 complete sentences)
           - SECONDARY: Stay within the word count range (accommodates language differences)
           - Write complete sentences only. Count sentences after writing.
           - VERIFY both sentence and word counts before responding.

        3. ⚠️ STYLE: Follow the GENERATION_STYLE exactly (witty, professional, engaging, etc.)

        **Excerpt best practices**
        - Follow WordPress ecosystem best practices for post excerpts
        - Include the post's main value proposition
        - Use active voice (avoid "is", "are", "was", "were" when possible)
        - End with implicit promise of more information (no ellipsis)
        - Include strategic keywords naturally
        - Write independently from the introduction – don't duplicate the opening paragraph
        - Make excerpts work as standalone copy for search results, social media, and email
        """
    }

    /// Creates a prompt for this excerpt configuration.
    public func makePrompt(content: String) -> String {
        """
        Generate EXACTLY 3 different excerpts for the given post.

        TARGET_LENGTH: \(length.promptModifier)
        CRITICAL: Write \(length.sentenceRange.lowerBound)-\(length.sentenceRange.upperBound) complete sentences. Stay within \(length.wordRange.lowerBound)-\(length.wordRange.upperBound) words.

        GENERATION_STYLE: \(style.promptModifier)

        POST_CONTENT:
        \(content)
        """
    }

    /// Prompt for generating additional excerpt options.
    public static var loadMorePrompt: String {
        "Generate 3 additional excerpts following the same TARGET_LENGTH and GENERATION_STYLE requirements"
    }

    // MARK: - Result Type

    @Generable
    public struct Result {
        @Guide(description: "Suggested post excerpts", .count(3))
        public var excerpts: [String]
    }
}
