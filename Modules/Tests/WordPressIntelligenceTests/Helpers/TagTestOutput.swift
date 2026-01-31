import Foundation
import NaturalLanguage

/// Structured output for tag suggestion tests that can be consumed by evaluation scripts.
struct TagTestOutput: Codable {
    let testType: String
    let testName: String
    let language: String
    let originalContent: String
    let siteTags: [String]
    let existingPostTags: [String]
    let tags: [String]
    let duration: Double
    let timestamp: String

    /// Convenience initializer that accepts TagTestCaseParameters and Duration.
    init(
        parameters: TagTestCaseParameters,
        tags: [String],
        duration: Duration
    ) {
        self.testType = "tag-suggestion"
        self.testName = parameters.testDescription
        self.language = parameters.data.languageCode.rawValue
        self.originalContent = parameters.data.content
        self.siteTags = parameters.siteTags
        self.existingPostTags = parameters.postTags
        self.tags = tags
        self.duration = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
        self.timestamp = ISO8601DateFormatter().string(from: Date())
    }

    /// Record test output to console for extraction and print formatted results.
    /// Emits base64-encoded JSON between markers for reliable parsing.
    /// This output can be extracted and evaluated by external tools.
    func recordAndPrint(parameters: TagTestCaseParameters, duration: Duration) throws {
        // Always record structured output for evaluation script
        try record()

        // Print formatted results for readability
        TestHelpers.printTagResults(
            parameters: parameters,
            tags: tags,
            duration: duration
        )
    }

    /// Record test output to console for extraction.
    /// Emits base64-encoded JSON between markers for reliable parsing.
    /// This output can be extracted and evaluated by external tools.
    private func record() throws {
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let jsonData = try encoder.encode(self)

        // Base64 encode for safe console transmission
        let base64String = jsonData.base64EncodedString()

        // Emit structured output with markers
        print("__TAG_OUTPUT_START__")
        print(base64String)
        print("__TAG_OUTPUT_END__")
    }
}
