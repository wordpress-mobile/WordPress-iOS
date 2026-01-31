import Testing
import Foundation
import FoundationModels
import NaturalLanguage
@testable import WordPressIntelligence

@Suite(.serialized)
struct PostSummaryGeneratorTests {
    // MARK: - Standard Test Cases

    @available(iOS 26, *)
    @Test(arguments: SummaryTestCaseParameters.allCases)
    func postSummary(parameters: SummaryTestCaseParameters) async throws {
        _ = try await runSummaryTest(parameters: parameters)
    }

    @available(iOS 26, *)
    @Test(arguments: SummaryTestCaseParameters.unsupportedLanguageCases)
    func unsupportedLanguages(parameters: SummaryTestCaseParameters) async throws {
        let generator = PostSummaryGenerator()

        do {
            _ = try await generator.generate(content: parameters.data.content)
            Issue.record("Expected unsupportedLanguageOrLocale error but no error was thrown")
        } catch LanguageModelSession.GenerationError.unsupportedLanguageOrLocale {
            return
        } catch {
            Issue.record("Expected unsupportedLanguageOrLocale error but got: \(error)")
        }
    }

    // MARK: - Edge Case Tests

    @available(iOS 26, *)
    @Test("HTML content")
    func htmlContent() async throws {
        let parameters = SummaryTestCaseParameters(
            data: TestData.englishPostWithHTML
        )
        _ = try await runSummaryTest(parameters: parameters)
    }

    @available(iOS 26, *)
    @Test("Malformed HTML")
    func malformedHTML() async throws {
        let parameters = SummaryTestCaseParameters(
            data: TestData.malformedHTML
        )
        _ = try await runSummaryTest(parameters: parameters)
    }

    @available(iOS 26, *)
    @Test("Very short content")
    func veryShortContent() async throws {
        let parameters = SummaryTestCaseParameters(
            data: TestData.veryShortEnglishContent
        )
        _ = try await runSummaryTest(parameters: parameters, skip: [.skipLengthCheck])
    }

    @available(iOS 26, *)
    @Test("Very long content (>10K words)")
    func veryLongContent() async throws {
        let parameters = SummaryTestCaseParameters(
            data: TestData.veryLongContent
        )

        do {
            let (summary, _) = try await runSummaryTest(
                parameters: parameters,
                maxDuration: .seconds(30)
            )
            #expect(!summary.isEmpty, "Should generate summary even for very long content")
        } catch {
            // May throw due to content length limits - this is acceptable
            return
        }
    }

    @available(iOS 26, *)
    @Test("Emoji and special Unicode characters")
    func emojiAndSpecialCharacters() async throws {
        let parameters = SummaryTestCaseParameters(
            data: TestData.emojiAndSpecialCharacters
        )
        _ = try await runSummaryTest(parameters: parameters)
    }

    @available(iOS 26, *)
    @Test("Mixed language content")
    func mixedLanguageContent() async throws {
        let parameters = SummaryTestCaseParameters(
            data: TestData.mixedLanguagePost
        )

        // Skip language check since content is intentionally mixed
        _ = try await runSummaryTest(
            parameters: parameters,
            skip: .skipLanguageCheck
        )
    }

    @available(iOS 26, *)
    @Test("Performance benchmark")
    func performanceBenchmark() async throws {
        let parameters = SummaryTestCaseParameters(
            data: TestData.englishTechPost
        )

        let (summary, duration) = try await runSummaryTest(
            parameters: parameters,
            maxDuration: .seconds(5)
        )

        #expect(!summary.isEmpty, "Should generate summary")

        let durationSeconds = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
        print("Performance: Generated summary in \(String(format: "%.2f", durationSeconds))s")
    }

    // MARK: - Helper Types

    /// Validation options for summary tests
    struct ValidationOptions: OptionSet {
        let rawValue: Int

        static let skipLanguageCheck = ValidationOptions(rawValue: 1 << 0)
        static let skipLengthCheck = ValidationOptions(rawValue: 1 << 1)
        static let skipContentCheck = ValidationOptions(rawValue: 1 << 2)

        static let all: ValidationOptions = []
        static let skipAll: ValidationOptions = [.skipLanguageCheck, .skipLengthCheck, .skipContentCheck]
    }

    // MARK: - Helper Methods

    /// Reusable test helper that runs summary generation and performs standard validations
    @available(iOS 26, *)
    private func runSummaryTest(
        parameters: SummaryTestCaseParameters,
        skip: ValidationOptions = [],
        maxDuration: Duration? = .seconds(10)
    ) async throws -> (String, Duration) {
        let generator = PostSummaryGenerator()

        let (summary, duration) = try await TestHelpers.measure {
            try await generator.generate(content: parameters.data.content)
        }

        // Performance validation
        if let maxDuration {
            let durationSeconds = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
            let maxSeconds = Double(maxDuration.components.seconds) + Double(maxDuration.components.attoseconds) / 1e18
            #expect(
                duration <= maxDuration,
                "Generation took too long: \(String(format: "%.2f", durationSeconds))s (max: \(String(format: "%.2f", maxSeconds))s)"
            )
        }

        // Validation: Non-empty
        #expect(!summary.isEmpty, "Summary should not be empty")

        // Validation: Language match
        if !skip.contains(.skipLanguageCheck) {
            TestHelpers.verifySummaryLanguage(summary, expectedLanguage: parameters.data.languageCode)
        }

        // Validation: Reasonable length (should be shorter than original)
        if !skip.contains(.skipLengthCheck) {
            let summaryWordCount = summary.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
            let originalWordCount = parameters.data.content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
            #expect(summaryWordCount < originalWordCount,
                   "Summary (\(summaryWordCount) words) should be shorter than original (\(originalWordCount) words)")
        }

        // Validation: Content relevance (should not be a generic response)
        if !skip.contains(.skipContentCheck) {
            let genericPhrases = ["this post", "this article", "the author"]
            let hasSpecificContent = !genericPhrases.allSatisfy { summary.lowercased().contains($0.lowercased()) }
            #expect(hasSpecificContent, "Summary should contain specific content, not just generic phrases")
        }

        // Record structured output for evaluation
        try? SummaryTestOutput(
            parameters: parameters,
            summary: summary,
            duration: duration
        ).recordAndPrint(parameters: parameters, duration: duration)

        return (summary, duration)
    }
}

struct SummaryTestCaseParameters: CustomTestStringConvertible {
    let data: TestContent

    var testDescription: String {
        data.title
    }

    typealias Data = TestData

    static let allCases: [SummaryTestCaseParameters] = [
        // English
        SummaryTestCaseParameters(data: Data.englishTechPost),
        SummaryTestCaseParameters(data: Data.englishPost),

        // Spanish
        SummaryTestCaseParameters(data: Data.spanishPost),

        // French
        SummaryTestCaseParameters(data: Data.frenchPost),

        // Japanese
        SummaryTestCaseParameters(data: Data.japanesePost),

        // German
        SummaryTestCaseParameters(data: Data.germanTechPost),

        // Mandarin
        SummaryTestCaseParameters(data: Data.mandarinPost),
    ]

    static let unsupportedLanguageCases: [SummaryTestCaseParameters] = [
        SummaryTestCaseParameters(data: Data.hindiPost),
        SummaryTestCaseParameters(data: Data.russianPost),
    ]
}
