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
        let prompt = makePrompt(content: content)
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

        \(IntelligenceService.makeLocaleInstructions())

        Do not include anything other than the summary in the response.
        """
    }

    /// Builds the prompt for summarizing post content.
    ///
    /// - Parameter content: The post content to summarize
    /// - Returns: Formatted prompt string
    public func makePrompt(content: String) -> String {
        let extractedContent = IntelligenceService.extractRelevantText(from: content, ratio: 0.8)

        return """
        Summarize the following post:

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
