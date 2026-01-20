import Testing
import Foundation
import FoundationModels
import NaturalLanguage
@testable import WordPressIntelligence

@Suite(.serialized)
struct PostExcerptGeneratorTests {
    // MARK: - Standard Test Cases

    @available(iOS 26, *)
    @Test(arguments: ExcerptTestCaseParameters.englishCases)
    func excerptGenerationEnglish(parameters: ExcerptTestCaseParameters) async throws {
        _ = try await runExcerptTest(parameters: parameters)
    }

    @available(iOS 26, *)
    @Test(arguments: ExcerptTestCaseParameters.nonEnglishCases)
    func excerptGenerationNonEnglish(parameters: ExcerptTestCaseParameters) async throws {
        _ = try await runExcerptTest(parameters: parameters)
    }

    @available(iOS 26, *)
    @Test(arguments: ExcerptTestCaseParameters.unsupportedLanguageCases)
    func unsupportedLanguages(parameters: ExcerptTestCaseParameters) async throws {
        let generator = PostExcerptGenerator(length: parameters.length, style: parameters.style)

        do {
            _ = try await generator.generate(for: parameters.data.content)
            Issue.record("Expected unsupportedLanguageOrLocale error but no error was thrown")
        } catch LanguageModelSession.GenerationError.unsupportedLanguageOrLocale {
            return
        } catch {
            Issue.record("Expected unsupportedLanguageOrLocale error but got: \(error)")
        }
    }

    @available(iOS 26, *)
    @Test("HTML content")
    func htmlContent() async throws {
        let parameters = ExcerptTestCaseParameters(
            data: TestData.englishPostWithHTML,
            length: .medium,
            style: .engaging
        )
        _ = try await runExcerptTest(parameters: parameters)
    }

    @available(iOS 26, *)
    @Test("Very short content")
    func veryShortContent() async throws {
        let parameters = ExcerptTestCaseParameters(
            data: TestData.veryShortEnglishContent,
            length: .short,
            style: .engaging
        )
        _ = try await runExcerptTest(parameters: parameters)
    }

    // MARK: - Error Handling Tests

    @available(iOS 26, *)
    @Test("Empty content")
    func emptyContent() async throws {
        let parameters = ExcerptTestCaseParameters(
            data: TestData.emptyContent,
            length: .short,
            style: .engaging
        )
        let generator = PostExcerptGenerator(length: parameters.length, style: parameters.style)

        // Empty content should either throw an error or return empty excerpts
        do {
            let excerpts = try await generator.generate(for: parameters.data.content)
            // If it doesn't throw, verify it returns empty or sensible default
            #expect(excerpts.isEmpty || excerpts.allSatisfy { $0.isEmpty })
        } catch {
            // Expected to throw for empty content - this is acceptable behavior
            return
        }
    }

    @available(iOS 26, *)
    @Test("Very long content (>10K words)")
    func veryLongContent() async throws {
        let parameters = ExcerptTestCaseParameters(
            data: TestData.veryLongContent,
            length: .medium,
            style: .professional
        )

        // Should handle gracefully - either generate excerpts or throw appropriate error
        // Allow longer processing time for very long content
        do {
            let (excerpts, _) = try await runExcerptTest(
                parameters: parameters,
                maxDuration: .seconds(30)
            )

            // If successful, verify excerpts are reasonable despite long input
            #expect(!excerpts.isEmpty)

            // Word count should still be within bounds
            for excerpt in excerpts {
                let wordCount = TestHelpers.countWords(excerpt, language: .english)
                #expect(parameters.length.wordRange.contains(wordCount),
                       "Word count \(wordCount) out of range for long content")
            }
        } catch {
            // May throw due to content length limits - this is acceptable
            return
        }
    }

    @available(iOS 26, *)
    @Test("Performance benchmark")
    func performanceBenchmark() async throws {
        let parameters = ExcerptTestCaseParameters(
            data: TestData.englishTechPost,
            length: .medium,
            style: .engaging
        )

        // Standard content should complete within 5 seconds
        let (excerpts, duration) = try await runExcerptTest(
            parameters: parameters,
            maxDuration: .seconds(5)
        )

        // Verify generation was successful
        #expect(!excerpts.isEmpty)

        // Log performance for tracking
        let durationSeconds = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
        print("Performance: Generated \(excerpts.count) excerpts in \(String(format: "%.2f", durationSeconds))s")
    }

    @available(iOS 26, *)
    @Test("Malformed HTML")
    func malformedHTML() async throws {
        let parameters = ExcerptTestCaseParameters(
            data: TestData.malformedHTML,
            length: .short,
            style: .conversational
        )

        // Should handle malformed HTML gracefully (extract text or clean it up)
        let (excerpts, _) = try await runExcerptTest(parameters: parameters)

        // Verify excerpts don't contain HTML tags
        for excerpt in excerpts {
            #expect(!excerpt.contains("<") && !excerpt.contains(">"),
                   "Excerpt should not contain HTML tags: \(excerpt)")
        }

        // Verify excerpts are not empty (HTML was successfully processed)
        #expect(!excerpts.isEmpty)
        #expect(excerpts.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
    }

    @available(iOS 26, *)
    @Test("Content with emojis and special Unicode characters")
    func emojiAndSpecialCharacters() async throws {
        let parameters = ExcerptTestCaseParameters(
            data: TestData.emojiAndSpecialCharacters,
            length: .medium,
            style: .engaging
        )

        let (excerpts, _) = try await runExcerptTest(parameters: parameters)

        // Verify excerpts are generated successfully
        #expect(!excerpts.isEmpty)

        // Verify excerpts handle Unicode correctly (no corruption or truncation)
        for excerpt in excerpts {
            // Should not be empty after Unicode processing
            #expect(!excerpt.trimmingCharacters(in: .whitespaces).isEmpty)

            // Check that excerpts preserve some Unicode content or handle it gracefully
            // (may or may not include emojis depending on generation logic)
            let hasContent = excerpt.count > 10
            #expect(hasContent, "Excerpt should have meaningful content despite Unicode")
        }
    }

    @available(iOS 26, *)
    @Test("Mixed language content")
    func mixedLanguageContent() async throws {
        let parameters = ExcerptTestCaseParameters(
            data: TestData.mixedLanguagePost,
            length: .medium,
            style: .professional
        )

        // Skip language check since content is intentionally mixed
        let (excerpts, _) = try await runExcerptTest(
            parameters: parameters,
            skip: .skipLanguageCheck
        )

        // Should generate excerpts for mixed language content
        #expect(!excerpts.isEmpty)

        // Verify excerpts have reasonable word counts
        for excerpt in excerpts {
            let wordCount = TestHelpers.countWords(excerpt, language: .english)
            #expect(parameters.length.wordRange.contains(wordCount),
                   "Mixed language excerpt word count \(wordCount) out of range")
        }
    }

    // MARK: - Helper Types

    /// Validation options for excerpt generation tests
    struct ValidationOptions: OptionSet {
        let rawValue: Int

        static let skipLanguageCheck = ValidationOptions(rawValue: 1 << 0)
        static let skipWordCountCheck = ValidationOptions(rawValue: 1 << 1)
        static let skipDiversityCheck = ValidationOptions(rawValue: 1 << 2)

        static let all: ValidationOptions = []
        static let skipAll: ValidationOptions = [.skipLanguageCheck, .skipWordCountCheck, .skipDiversityCheck]
    }

    // MARK: - Helper Methods

    /// Reusable test helper that runs excerpt generation and performs standard validations
    @available(iOS 26, *)
    private func runExcerptTest(
        parameters: ExcerptTestCaseParameters,
        skip: ValidationOptions = [],
        maxDuration: Duration? = .seconds(10)
    ) async throws -> ([String], Duration) {
        let generator = PostExcerptGenerator(length: parameters.length, style: parameters.style)

        let (excerpts, duration) = try await TestHelpers.measure {
            try await generator.generate(for: parameters.data.content)
        }

        // Performance benchmark
        if let maxDuration {
            let durationSeconds = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
            let maxSeconds = Double(maxDuration.components.seconds) + Double(maxDuration.components.attoseconds) / 1e18
            #expect(
                duration <= maxDuration,
                "Generation took too long: \(String(format: "%.2f", durationSeconds))s (max: \(String(format: "%.2f", maxSeconds))s)"
            )
        }

        if !skip.contains(.skipLanguageCheck) {
            TestHelpers.verifyExcerptsLanguage(excerpts, expectedLanguage: parameters.data.languageCode)
        }

        if !skip.contains(.skipWordCountCheck) {
            TestHelpers.verifyExcerptsWordCount(
                excerpts,
                wordRange: parameters.length.wordRange,
                language: parameters.data.languageCode
            )
        }

        if !skip.contains(.skipDiversityCheck) {
            TestHelpers.verifyExcerptsDiversity(excerpts)
        }

        try? ExcerptTestOutput(
            parameters: parameters,
            excerpts: excerpts,
            duration: duration
        ).recordAndPrint(parameters: parameters, duration: duration)

        return (excerpts, duration)
    }
}

struct ExcerptTestCaseParameters: CustomTestStringConvertible {
    let data: TestContent
    let length: ContentLength
    let style: WritingStyle

    var testDescription: String {
        "\(data.title) - \(length.displayName), \(style.displayName)"
    }

    typealias Data = TestData

    static let englishCases: [ExcerptTestCaseParameters] = [
        ExcerptTestCaseParameters(data: Data.englishTechPost, length: .short, style: .witty),
        ExcerptTestCaseParameters(data: Data.englishAcademicPost, length: .medium, style: .formal),
        ExcerptTestCaseParameters(data: Data.englishStoryPost, length: .long, style: .engaging),
    ]

    static let nonEnglishCases: [ExcerptTestCaseParameters] = [
        ExcerptTestCaseParameters(data: Data.spanishPost, length: .medium, style: .professional),
        ExcerptTestCaseParameters(data: Data.frenchPost, length: .short, style: .engaging),
        ExcerptTestCaseParameters(data: Data.japanesePost, length: .medium, style: .conversational),
        ExcerptTestCaseParameters(data: Data.germanTechPost, length: .short, style: .professional),
        ExcerptTestCaseParameters(data: Data.mandarinPost, length: .medium, style: .engaging),
    ]

    static let unsupportedLanguageCases: [ExcerptTestCaseParameters] = [
        ExcerptTestCaseParameters(data: Data.hindiPost, length: .short, style: .conversational),
        ExcerptTestCaseParameters(data: Data.russianPost, length: .medium, style: .formal),
    ]

    static let allCases: [ExcerptTestCaseParameters] = englishCases + nonEnglishCases
}
