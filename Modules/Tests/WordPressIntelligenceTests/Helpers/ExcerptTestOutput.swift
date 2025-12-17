import Foundation
import NaturalLanguage

/// Structured output for excerpt tests that can be consumed by evaluation scripts.
struct ExcerptTestOutput: Codable {
    let testName: String
    let language: String
    let length: String
    let style: String
    let originalContent: String
    let excerpts: [String]
    let duration: Double
    let timestamp: String

    /// Convenience initializer that accepts ExcerptTestCaseParameters and Duration.
    init(
        parameters: ExcerptTestCaseParameters,
        excerpts: [String],
        duration: Duration
    ) {
        self.testName = parameters.testDescription
        self.language = parameters.data.languageCode.rawValue
        self.length = parameters.length.displayName
        self.style = parameters.style.displayName
        self.originalContent = parameters.data.content
        self.excerpts = excerpts
        self.duration = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
        self.timestamp = ISO8601DateFormatter().string(from: Date())
    }

    /// Record test output to console for extraction and print formatted results.
    /// Emits base64-encoded JSON between markers for reliable parsing.
    /// This output can be extracted and evaluated by external tools.
    func recordAndPrint(parameters: ExcerptTestCaseParameters, duration: Duration) throws {
        // Always record structured output for evaluation script
        try record()

        // Print formatted results for readability
        TestHelpers.printExcerptResults(
            parameters: parameters,
            excerpts: excerpts,
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
        print("__EXCERPT_OUTPUT_START__")
        print(base64String)
        print("__EXCERPT_OUTPUT_END__")
    }
}
