import Foundation
import FoundationModels

@available(iOS 26, *)
public actor IntelligenceService {
    /// A single token corresponds to three or four characters in languages like
    /// English, Spanish, or German, and one token per character in languages like
    /// Japanese, Chinese, or Korean. In a single session, the sum of all tokens
    /// in the instructions, all prompts, and all outputs count toward the context window size.
    ///
    /// https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models#Consider-context-size-limits-per-session
    static let contextSizeLimit = 4096

    public nonisolated static var isSupported: Bool {
        LanguageModelHelper.isSupported
    }

    public init() {}

    /// Suggests tags for a WordPress post.
    ///
    /// - Parameters:
    ///   - post: The content of the WordPress post.
    ///   - siteTags: An array of existing tags used elsewhere on the site.
    ///   - postTags: An array of tags already assigned to the post.
    ///
    /// - Returns: An array of suggested tags.
    public func suggestTags(post: String, siteTags: [String] = [], postTags: [String] = []) async throws -> [String] {
        let startTime = CFAbsoluteTimeGetCurrent()

        // We have to be mindful of the content size limit, so we
        // only support a subset of tags, preamptively remove Gutenberg tags
        // from the content, and limit the content size.

        // A maximum of 500 characters assuming 10 characters per
        let siteTags = siteTags.prefix(50)
        let post = extractRelevantText(from: post)

        try Task.checkCancellation()

        // Notes:
        // - It was critical to add "case-sensitive" as otherwise it would ignore
        // case sensitivity and pick the wrong output format.
        // - The lowered temperature helped improved the accuracy.
        // - `useCase: .contentTagging` is not recommended for arbitraty hashtags

        let instructions = """
        You are helping a WordPress user add tags to a post or a page.

        **Parameters**
        - POST_CONTENT: contents of the post (HTML or plain text)
        - SITE_TAGS: case-sensitive comma-separated list of the existing tags used elsewhere on the site (not always relevant to the post)
        - EXISTING_POST_TAGS: tags already added to the post

        **Steps**
        - 1. Identify the specific formatting pattern used (e.g., lowercase with underscores, capitalized words with spaces, etc)
        - 2. Generate a list of ten most relevant suggested tags based on POST_CONTENT and SITE_TAGS relevant to the content.

        **Requirements**
        - Do not include any tags from EXISTING_POST_TAGS
        - If there are no relevant suggestions, returns an empty list
        - Do not produce any output other than the final list of tag
        """

        let session = LanguageModelSession(
            model: .init(guardrails: .permissiveContentTransformations),
            instructions: instructions
        )

        let prompt = """
        Suggest up to ten tags for a post.

        POST_CONTENT: '''
        \(post)
        '''

        SITE_TAGS: '\(siteTags.joined(separator: ", "))'

        EXISTING_POST_TAGS: '\(postTags.joined(separator: ", "))'
        """

        let response = try await session.respond(
            to: prompt,
            generating: SuggestedTagsResult.self,
            options: GenerationOptions(temperature: 0.2)
        )

        WPLogInfo("IntelligenceService.suggestTags executed in \((CFAbsoluteTimeGetCurrent() - startTime) * 1000) ms")

        let existingPostTags = Set(postTags)
        return response.content.tags
            .deduplicated()
            .filter { !existingPostTags.contains($0) }
    }

    /// Summarizes a WordPress post.
    ///
    /// - Parameter content: The content of the WordPress post (HTML or plain text).
    /// - Returns: An async stream of partial summaries as they are generated.
    public func summarizePost(content: String) -> LanguageModelSession.ResponseStream<String> {
        let content = extractRelevantText(from: content, ratio: 0.8)

        let instructions = """
        You are helping a WordPress user understand the content of a post.
        Generate a concise summary that captures the main points and key information.
        The summary should be clear, informative, and written in a neutral tone.

        Do not include anything other than the summary in the response.
        """

        let session = LanguageModelSession(
            model: .init(guardrails: .permissiveContentTransformations),
            instructions: instructions
        )

        let prompt = """
        Summarize the following post:

        \(content)
        """

        return session.streamResponse(to: prompt)
    }

    public nonisolated func extractRelevantText(from post: String, ratio: CGFloat = 0.6) -> String {
        let extract = try? IntelligenceUtilities.extractRelevantText(from: post)
        let postSizeLimit = Double(IntelligenceService.contextSizeLimit) * ratio
        return String((extract ?? post).prefix(Int(postSizeLimit)))
    }
}

private extension Array where Element: Hashable {
    func deduplicated() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

@available(iOS 26, *)
@Generable
private struct SuggestedTagsResult {
    @Guide(description: "Newly generated tags following the identified format")
    var tags: [String]
}
