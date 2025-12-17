import Foundation
import FoundationModels

/// Post summarization for WordPress content.
///
/// Generates concise summaries that capture the main points and key information
/// from WordPress post content in the same language as the source.
///
/// Example usage:
/// ```swift
/// let summary = PostSummary()
/// let result = try await summary.generate(content: postContent)
/// ```
@available(iOS 26, *)
public struct PostSummaryGenerator {
    public var options: GenerationOptions

    public init(options: GenerationOptions = GenerationOptions(temperature: 0.3)) {
        self.options = options
    }

    /// Generate a summary for the given post content.
    ///
    /// - Parameter content: The post content to summarize (HTML or plain text)
    /// - Returns: A concise summary in the same language as the source
    /// - Throws: If the language model session fails
    public func generate(content: String) async throws -> String {
        let session = makeSession()
        let prompt = await makePrompt(content: content)
        return try await session.respond(to: prompt).content
    }

    /// Creates a language model session configured for post summarization.
    ///
    /// - Returns: Configured session with instructions
    public func makeSession() -> LanguageModelSession {
        LanguageModelSession(
            model: .init(guardrails: .permissiveContentTransformations),
            instructions: Self.instructions
        )
    }

    /// Instructions for the language model on how to generate summaries.
    public static var instructions: String {
        """
        You are helping a WordPress user understand the content of a post.
        Generate a concise summary that captures the main points and key information.
        The summary should be clear, informative, and written in a neutral tone.

        **Prompt Parameters**
        - POST_CONTENT: contents of the post (HTML or plain text)
        - TARGET_LANGUAGE: the detected language code of POST_CONTENT (e.g., "en", "es", "fr", "ja") when available

        \(IntelligenceService.makeLocaleInstructions())

        **CRITICAL Requirement**
        ⚠️ LANGUAGE: Generate summary in the language specified by TARGET_LANGUAGE code if provided, otherwise match POST_CONTENT language exactly. NO translation. NO defaulting to English. Match input language EXACTLY.

        Do not include anything other than the summary in the response.
        """
    }

    /// Builds the prompt for summarizing post content.
    ///
    /// This method handles content extraction (removing HTML, limiting size) and language detection
    /// automatically before creating the prompt.
    ///
    /// - Parameter content: The raw post content (may include HTML)
    /// - Returns: Formatted prompt string ready for the language model
    public func makePrompt(content: String) async -> String {
        let extractedContent = IntelligenceService.extractRelevantText(from: content, ratio: 0.8)
        let language = IntelligenceService.detectLanguage(from: extractedContent)
        let languageInstruction = language.map { "TARGET_LANGUAGE: \($0)\n\n" } ?? ""

        return """
        Summarize the following post:

        \(languageInstruction)POST_CONTENT:
        \(extractedContent)
        """
    }
}

@available(iOS 26, *)
extension IntelligenceService {
    /// Post summarization for WordPress content.
    ///
    /// - Parameter content: The post content to summarize
    /// - Returns: A concise summary
    /// - Throws: If summarization fails
    public func summarize(content: String) async throws -> String {
        try await PostSummaryGenerator().generate(content: content)
    }
}
