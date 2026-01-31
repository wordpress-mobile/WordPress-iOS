import Testing
import Foundation
import FoundationModels
import NaturalLanguage
@testable import WordPressIntelligence

@Suite(.serialized)
struct TagSuggestionGeneratorTests {
    // MARK: - Standard Test Cases

    @available(iOS 26, *)
    @Test(arguments: TagTestCaseParameters.englishCases)
    func tagSuggestionEnglish(parameters: TagTestCaseParameters) async throws {
        _ = try await runTagTest(parameters: parameters)
    }

    @available(iOS 26, *)
    @Test(arguments: TagTestCaseParameters.nonEnglishCases)
    func tagSuggestionNonEnglish(parameters: TagTestCaseParameters) async throws {
        _ = try await runTagTest(parameters: parameters)
    }

    @available(iOS 26, *)
    @Test(arguments: TagTestCaseParameters.unsupportedLanguageCases)
    func unsupportedLanguages(parameters: TagTestCaseParameters) async throws {
        let generator = TagSuggestionGenerator()

        do {
            _ = try await generator.generate(
                post: parameters.data.content,
                siteTags: parameters.siteTags,
                postTags: parameters.postTags
            )
            Issue.record("Expected unsupportedLanguageOrLocale error but no error was thrown")
        } catch LanguageModelSession.GenerationError.unsupportedLanguageOrLocale {
            return
        } catch {
            Issue.record("Expected unsupportedLanguageOrLocale error but got: \(error)")
        }
    }

    // MARK: - Edge Case Tests

    @available(iOS 26, *)
    @Test("Exclude existing post tags")
    func excludeExistingTags() async throws {
        let parameters = TagTestCaseParameters(
            data: TestData.englishTechPost,
            siteTags: TestData.englishSiteTags,
            postTags: ["programming", "technology"]
        )
        let (tags, _) = try await runTagTest(parameters: parameters)

        #expect(!tags.contains { parameters.postTags.contains($0) },
               "Tags should not include existing post tags: \(parameters.postTags)")
    }

    @available(iOS 26, *)
    @Test("Empty site tags")
    func emptySiteTags() async throws {
        let parameters = TagTestCaseParameters(
            data: TestData.englishPost,
            siteTags: [],
            postTags: []
        )
        _ = try await runTagTest(parameters: parameters)
    }

    @available(iOS 26, *)
    @Test("Very short content")
    func veryShortContent() async throws {
        let parameters = TagTestCaseParameters(
            data: TestData.veryShortEnglishContent,
            siteTags: TestData.englishSiteTags,
            postTags: []
        )
        _ = try await runTagTest(parameters: parameters)
    }

    @available(iOS 26, *)
    @Test("Very long content (>10K words)")
    func veryLongContent() async throws {
        let parameters = TagTestCaseParameters(
            data: TestData.veryLongContent,
            siteTags: TestData.englishSiteTags,
            postTags: []
        )

        do {
            let (tags, _) = try await runTagTest(
                parameters: parameters,
                maxDuration: .seconds(30)
            )
            #expect(!tags.isEmpty, "Should generate tags even for very long content")
        } catch {
            // May throw due to content length limits - this is acceptable
            return
        }
    }

    @available(iOS 26, *)
    @Test("HTML content")
    func htmlContent() async throws {
        let parameters = TagTestCaseParameters(
            data: TestData.englishPostWithHTML,
            siteTags: TestData.englishSiteTags,
            postTags: []
        )
        _ = try await runTagTest(parameters: parameters)
    }

    @available(iOS 26, *)
    @Test("Malformed HTML")
    func malformedHTML() async throws {
        let parameters = TagTestCaseParameters(
            data: TestData.malformedHTML,
            siteTags: TestData.englishSiteTags,
            postTags: []
        )
        _ = try await runTagTest(parameters: parameters)
    }

    @available(iOS 26, *)
    @Test("Emoji and special Unicode characters")
    func emojiAndSpecialCharacters() async throws {
        let parameters = TagTestCaseParameters(
            data: TestData.emojiAndSpecialCharacters,
            siteTags: TestData.englishSiteTags,
            postTags: []
        )
        _ = try await runTagTest(parameters: parameters)
    }

    @available(iOS 26, *)
    @Test("Mixed language content")
    func mixedLanguageContent() async throws {
        let parameters = TagTestCaseParameters(
            data: TestData.mixedLanguagePost,
            siteTags: TestData.englishSiteTags,
            postTags: []
        )

        // Skip language check since content is intentionally mixed
        _ = try await runTagTest(
            parameters: parameters,
            skip: .skipLanguageCheck
        )
    }

    @available(iOS 26, *)
    @Test("Performance benchmark")
    func performanceBenchmark() async throws {
        let parameters = TagTestCaseParameters(
            data: TestData.englishTechPost,
            siteTags: TestData.englishSiteTags,
            postTags: []
        )

        let (tags, duration) = try await runTagTest(
            parameters: parameters,
            maxDuration: .seconds(5)
        )

        #expect(!tags.isEmpty, "Should generate tags")

        let durationSeconds = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
        print("Performance: Generated \(tags.count) tags in \(String(format: "%.2f", durationSeconds))s")
    }

    // MARK: - Helper Types

    /// Validation options for tag suggestion tests
    struct ValidationOptions: OptionSet {
        let rawValue: Int

        static let skipLanguageCheck = ValidationOptions(rawValue: 1 << 0)
        static let skipFormatCheck = ValidationOptions(rawValue: 1 << 1)
        static let skipCountCheck = ValidationOptions(rawValue: 1 << 2)

        static let all: ValidationOptions = []
        static let skipAll: ValidationOptions = [.skipLanguageCheck, .skipFormatCheck, .skipCountCheck]
    }

    // MARK: - Helper Methods

    /// Reusable test helper that runs tag generation and performs standard validations
    @available(iOS 26, *)
    private func runTagTest(
        parameters: TagTestCaseParameters,
        skip: ValidationOptions = [],
        maxDuration: Duration? = .seconds(10)
    ) async throws -> ([String], Duration) {
        let generator = TagSuggestionGenerator()

        let (tags, duration) = try await TestHelpers.measure {
            try await generator.generate(
                post: parameters.data.content,
                siteTags: parameters.siteTags,
                postTags: parameters.postTags
            )
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

        // Validation: Language match
        if !skip.contains(.skipLanguageCheck) {
            TestHelpers.verifyTagsLanguage(tags, expectedLanguage: parameters.data.languageCode)
        }

        // Validation: Format consistency
        if !skip.contains(.skipFormatCheck) && !parameters.siteTags.isEmpty {
            TestHelpers.verifyTagsFormat(tags, siteTags: parameters.siteTags)
        }

        // Validation: Count (5-10 tags as per @Guide)
        if !skip.contains(.skipCountCheck) {
            #expect(tags.count >= 5 && tags.count <= 10,
                   "Expected 5-10 tags, got \(tags.count)")
        }

        // Validation: Uniqueness
        let uniqueTags = Set(tags)
        #expect(uniqueTags.count == tags.count,
               "Tags contain duplicates: \(tags)")

        // Validation: No existing post tags
        let existingPostTags = Set(parameters.postTags)
        #expect(!tags.contains { existingPostTags.contains($0) },
               "Tags should not include existing post tags")

        // Record structured output for evaluation
        try? TagTestOutput(
            parameters: parameters,
            tags: tags,
            duration: duration
        ).recordAndPrint(parameters: parameters, duration: duration)

        return (tags, duration)
    }
}

struct TagTestCaseParameters: CustomTestStringConvertible {
    let data: TestContent
    let siteTags: [String]
    let postTags: [String]

    var testDescription: String {
        "\(data.title) - \(siteTags.count) site tags"
    }

    typealias Data = TestData

    static let englishCases: [TagTestCaseParameters] = [
        TagTestCaseParameters(data: Data.englishTechPost, siteTags: Data.englishSiteTags, postTags: []),
        TagTestCaseParameters(data: Data.englishPost, siteTags: Data.englishSiteTags, postTags: []),
    ]

    static let nonEnglishCases: [TagTestCaseParameters] = [
        TagTestCaseParameters(data: Data.spanishPost, siteTags: Data.spanishSiteTags, postTags: []),
        TagTestCaseParameters(data: Data.frenchPost, siteTags: Data.frenchSiteTags, postTags: []),
        TagTestCaseParameters(data: Data.japanesePost, siteTags: Data.japaneseSiteTags, postTags: []),
        TagTestCaseParameters(data: Data.germanTechPost, siteTags: Data.germanSiteTags, postTags: []),
        TagTestCaseParameters(data: Data.mandarinPost, siteTags: Data.mandarinSiteTags, postTags: []),
    ]

    static let unsupportedLanguageCases: [TagTestCaseParameters] = [
        TagTestCaseParameters(data: Data.hindiPost, siteTags: [], postTags: []),
        TagTestCaseParameters(data: Data.russianPost, siteTags: [], postTags: []),
    ]

    static let allCases: [TagTestCaseParameters] = englishCases + nonEnglishCases
}
