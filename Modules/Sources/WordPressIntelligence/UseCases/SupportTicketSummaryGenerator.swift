import Foundation
import FoundationModels

/// Support ticket summarization.
///
/// Generates short, concise titles (fewer than 10 words) for support
/// conversations based on the opening message.
@available(iOS 26, *)
public enum SupportTicketSummaryGenerator {
    public static func execute(content: String) async throws -> String {
        let instructions = """
            You are helping a user by summarizing their support request down to a single sentence
            with fewer than 10 words.

            The summary should be clear, informative, and written in a neutral tone.
            You MUST generate the summary in the same language as the support request.

            Do not include anything other than the summary in the response.
            """

        let session = LanguageModelSession(
            model: .init(guardrails: .permissiveContentTransformations),
            instructions: instructions
        )

        let prompt = """
            Give me an appropriate conversation title for the following opening message of the conversation:

            \(content)
            """

        return try await session.respond(
            to: prompt,
            generating: Result.self,
            options: GenerationOptions(temperature: 1.0)
        ).content.title
    }

    @Generable
    struct Result {
        @Guide(description: "The conversation title")
        var title: String
    }
}
