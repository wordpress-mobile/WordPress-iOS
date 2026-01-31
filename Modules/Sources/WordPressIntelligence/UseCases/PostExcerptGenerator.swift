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
        let prompt = await makePrompt(content: content)
        let response = try await makeSession().respond(
            to: prompt,
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

        **Parameters**
        - POST_CONTENT: post contents (HTML or plain text)
        - TARGET_LANGUAGE: detected language code (e.g., "en", "es", "fr", "ja")
        - TARGET_LENGTH: sentence count (primary) and word range (secondary)
        - GENERATION_STYLE: writing style to apply

        \(IntelligenceService.makeLocaleInstructions())

        **Requirements**
        1. ⚠️ LANGUAGE: Match TARGET_LANGUAGE code if provided, otherwise match POST_CONTENT language. Never translate or default to English.

        2. ⚠️ LENGTH: Match TARGET_LENGTH sentence count, stay within word range. Write complete sentences only.

        3. ⚠️ STYLE: Follow GENERATION_STYLE exactly.

        **Best Practices**
        - Capture the post's main value proposition
        - Use active voice and strategic keywords naturally
        - Don't duplicate the opening paragraph
        - Work as standalone copy for search results, social media, and email
        """
    }

    /// Creates a prompt for this excerpt configuration.
    ///
    /// This method handles content extraction (removing HTML, limiting size) and language detection
    /// automatically before creating the prompt.
    ///
    /// - Parameter content: The raw post content (may include HTML)
    /// - Returns: The formatted prompt ready for the language model
    public func makePrompt(content: String) async -> String {
        let extractedContent = IntelligenceService.extractRelevantText(from: content)
        let language = IntelligenceService.detectLanguage(from: extractedContent)
        let languageInstruction = language.map { "TARGET_LANGUAGE: \($0)\n" } ?? ""

        return """
        Generate EXACTLY 3 different excerpts for the given post.

        \(languageInstruction)TARGET_LENGTH: \(length.promptModifier)
        CRITICAL: Write \(length.sentenceRange.lowerBound)-\(length.sentenceRange.upperBound) complete sentences. Stay within \(length.wordRange.lowerBound)-\(length.wordRange.upperBound) words.

        GENERATION_STYLE: \(style.promptModifier)

        POST_CONTENT:
        \(extractedContent)
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
