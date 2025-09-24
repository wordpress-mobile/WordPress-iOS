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
        guard postTags.count < 20 else {
            return [] // No point suggesting more
        }

        // Step 0: We have to be mindful of the content size limit, so we
        // only support a subset of tags, preamptively remove Gutenberg tags
        // from the content, and limit the content size.

        // A maximum of 700 characters assuming 10 characters per
        let siteTags = siteTags.prefix(50)

        let postSizeLimit = Double(IntelligenceService.contextSizeLimit) * (2.0 / 3.0)
        let post = extractPlainText(from: post)
            .prefix(Int(postSizeLimit))

        // Notes:
        // - It was critical to add "case-sensitive" as otherwise it would ignore
        // case sensitivity and pick the wrong output format.
        // - The lowered temperature helped improved the accuracy.
        // - `useCase: .contentTagging` is not recommended for arbitraty hashtags

        let instructions = """
        You are helping a WordPress user add tags to a post or a page on their site.

        Parameters:
        - POST_CONTENT: The contents of the post.
        - SITE_TAGS: A case-sensitive comma-separated list of the existing tags used elsewhere on the site (can be empty). 
        - EXISTING_POST_TAGS: A list of tags already added to the post.

        Requirements:
        - Use the best practices for tagging posts and pages established in the WordPress ecocystem.
        - Use the same language as used for the SITE_TAGS.
        """

        let session = LanguageModelSession(
            model: .init(guardrails: .permissiveContentTransformations),
            instructions: instructions
        )

        // Step 1: Identify the format of existing tags
        let formatPrompt = """
        Analyze the formatting pattern used in these tags:

        SITE_TAGS: '\(siteTags.joined(separator: ", "))'
        EXISTING_POST_TAGS: '\(siteTags.joined(separator: ", "))'

        Identify the specific formatting pattern being used (e.g., lowercase with underscores, capitalized words with spaces, etc.). You will use this format for tag suggestions.
        """

        let formatResponse = try await session.respond(
            to: formatPrompt,
            generating: TagFormatAnalysisResult.self,
            options: GenerationOptions(temperature: 0.1)
        )

        // Step 2: Pick existing tags that match the content
        let matchingTagsPrompt = """
        Review the post content and determine which of the existing tags are relevant.

        POST_CONTENT: '''
        \(post)
        '''

        Select only the tags from SITE_TAGS that are directly relevant to the post content. Do not include any tags from EXISTING_POST_TAGS. If none match, return an empty list.
        """

        let matchingTagsResponse = try await session.respond(
            to: matchingTagsPrompt,
            generating: MatchingTagsResult.self,
            options: GenerationOptions(temperature: 0.1) // Accuracy over creativity
        )

        // Step 3: Generate new tags following the identified format
        let newTagsPrompt = """
        Generate suggested tags for the post content.

        Format requirement: \(formatResponse.content.formatDescription)

        Generate up to 10 new tags following the same format and naming conventions. Do not include any tags from SITE_TAGS or EXISTING_POST_TAGS.
        """

        let newTagsResponse = try await session.respond(
            to: newTagsPrompt,
            generating: NewTagsResult.self,
            options: GenerationOptions(temperature: 0.1)
        )

        // Combine picked existing tags with new tags
        let suggestedExistingTags = matchingTagsResponse.content.tags
        let suggestedNewTags = newTagsResponse.content.tags

        var encountered = Set(postTags)
        return (suggestedExistingTags + suggestedNewTags).filter {
            guard !encountered.contains($0) else { return false }
            encountered.insert($0)
            return true
        }
    }
}

private func extractPlainText(from html: String) -> String {
    guard let data = html.data(using: .utf8) else {
        return html
    }

    let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
        .documentType: NSAttributedString.DocumentType.html,
        .characterEncoding: String.Encoding.utf8.rawValue
    ]

    var content: String?
    try? WPException.objcTry {
        if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            content = attributedString.string
        }
    }

    return content ?? html
}

@available(iOS 26, *)
@Generable
private struct TagFormatAnalysisResult {
    @Guide(description: "A description of the formatting pattern used in the existing tags")
    var formatDescription: String
}

@available(iOS 26, *)
@Generable
private struct MatchingTagsResult {
    @Guide(description: "Tags from the existing tags list that match the post content")
    var tags: [String]
}

@available(iOS 26, *)
@Generable
private struct NewTagsResult {
    @Guide(description: "Newly generated tags following the identified format")
    var tags: [String]
}
