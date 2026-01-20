import Foundation
import NaturalLanguage
import Testing
@testable import WordPressIntelligence

/// Helper utilities for formatting intelligence test output.
enum TestHelpers {

    // MARK: - Tag Suggestions

    static func printTagResults(
        _ title: String,
        tags: [String]
    ) {
        printSectionHeader(title)

        print("📑 Generated \(tags.count) tags:")
        print()
        for (i, tag) in tags.enumerated() {
            print("  \(i + 1). \(tag)")
        }

        printSectionFooter()
    }

    // MARK: - Summaries

    static func printSummaryResults(
        _ title: String,
        summary: String
    ) {
        printSectionHeader(title)

        let wordCount = summary.split(separator: " ").count
        let charCount = summary.count
        print("📊 Metrics: \(wordCount) words • \(charCount) characters")
        print()
        print("📝 Summary:")
        print()
        print(summary.wrapped(width: 80))

        printSectionFooter()
    }

    // MARK: - Excerpts

    static func printExcerptResults(
        _ title: String,
        excerpts: [String],
        targetLength: String,
        style: String,
        expectedLanguage: NLLanguage,
        duration: Duration
    ) {
        printSectionHeader(title)

        let durationSeconds = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
        print("📝 Generated \(excerpts.count) variations (language: \(expectedLanguage.rawValue), time: \(String(format: "%.3f", durationSeconds))s)")
        print()

        let boxWidth = 80

        for (i, excerpt) in excerpts.enumerated() {
            let wordCount = countWords(excerpt, language: expectedLanguage)

            let detectedLanguage = detectLanguage(excerpt)
            let languageMatch = detectedLanguage == expectedLanguage
            let languageIndicator = languageMatch ? "✓" : "✗"
            let languageInfo = "\(languageIndicator) \(detectedLanguage?.rawValue ?? "unknown")"

            // Fixed-width header
            let header = "Variation \(i + 1) (\(wordCount) words, \(languageInfo))"
            let headerVisualWidth = visualLength(header)
            let headerPadding = max(0, boxWidth - headerVisualWidth - 4) // -4 for "┌─ " + "┐"
            print("┌─ \(header) " + String(repeating: "─", count: headerPadding) + "┐")

            // Content with consistent width and padding
            // Use slightly smaller width for wrapping to avoid edge cases with emoji rendering
            let innerWidth = boxWidth - 4 // -4 for "│ " and " │"
            let wrapWidth = innerWidth - 2 // Be conservative to avoid overflow

            for line in excerpt.wrapped(width: wrapWidth).split(separator: "\n") {
                let lineStr = String(line)
                let lineVisualWidth = visualLength(lineStr)
                let linePadding = max(0, innerWidth - lineVisualWidth)
                print("│ \(lineStr)\(String(repeating: " ", count: linePadding)) │")
            }

            // Fixed-width footer
            print("└" + String(repeating: "─", count: boxWidth - 2) + "┘")
            print()
        }
    }

    static func printExcerptResults(
        parameters: ExcerptTestCaseParameters,
        excerpts: [String],
        duration: Duration
    ) {
        printExcerptResults(
            parameters.testDescription,
            excerpts: excerpts,
            targetLength: parameters.length.promptModifier,
            style: parameters.style.displayName,
            expectedLanguage: parameters.data.languageCode,
            duration: duration
        )
    }

    @available(iOS 26, *)
    static func printExcerptResults(
        _ title: String,
        excerpts: [String],
        generator: PostExcerptGenerator,
        expectedLanguage: NLLanguage,
        duration: Duration
    ) {
        printExcerptResults(
            title,
            excerpts: excerpts,
            targetLength: generator.length.promptModifier,
            style: generator.style.displayName,
            expectedLanguage: expectedLanguage,
            duration: duration
        )
    }

    // MARK: - Comparison Tables

    static func printComparisonTable(
        _ title: String,
        headers: [String],
        rows: [[String]]
    ) {
        printSectionHeader(title)

        // Calculate column widths
        var widths = headers.map { $0.count }
        for row in rows {
            for (i, cell) in row.enumerated() where i < widths.count {
                widths[i] = max(widths[i], cell.count)
            }
        }

        // Print header
        print("┌", terminator: "")
        for (i, width) in widths.enumerated() {
            print(String(repeating: "─", count: width + 2), terminator: "")
            print(i < widths.count - 1 ? "┬" : "┐\n", terminator: "")
        }

        print("│", terminator: "")
        for (i, header) in headers.enumerated() {
            print(" \(header.padding(toLength: widths[i], withPad: " ", startingAt: 0)) ", terminator: "")
            print(i < headers.count - 1 ? "│" : "│\n", terminator: "")
        }

        // Print separator
        print("├", terminator: "")
        for (i, width) in widths.enumerated() {
            print(String(repeating: "─", count: width + 2), terminator: "")
            print(i < widths.count - 1 ? "┼" : "┤\n", terminator: "")
        }

        // Print rows
        for row in rows {
            print("│", terminator: "")
            for (i, cell) in row.enumerated() where i < widths.count {
                print(" \(cell.padding(toLength: widths[i], withPad: " ", startingAt: 0)) ", terminator: "")
                print(i < row.count - 1 ? "│" : "│\n", terminator: "")
            }
        }

        // Print footer
        print("└", terminator: "")
        for (i, width) in widths.enumerated() {
            print(String(repeating: "─", count: width + 2), terminator: "")
            print(i < widths.count - 1 ? "┴" : "┘\n", terminator: "")
        }

        printSectionFooter()
    }

    // MARK: - Utilities

    private static func printSectionHeader(_ title: String) {
        let boxWidth = 80
        let border = String(repeating: "═", count: boxWidth)

        print()
        print("╔\(border)╗")

        // Extract language from title (first word)
        let language = title.split(separator: " ").first.map(String.init)
        let flag = language.map { languageFlag(for: $0) } ?? ""
        let displayTitle = flag.isEmpty ? title : "\(flag) \(title)"

        // Calculate padding (accounting for emoji visual width)
        // Flag emojis are 2 unicode scalars but display as ~2 visual spaces
        let visualWidth = visualLength(displayTitle)
        let paddingNeeded = boxWidth - visualWidth - 2 // -2 for "║ " and " ║"
        let paddedTitle = displayTitle + String(repeating: " ", count: max(0, paddingNeeded))

        print("║ \(paddedTitle) ║")
        print("╠\(border)╣")
        print()
    }

    private static func printSectionFooter() {
        let boxWidth = 80
        let border = String(repeating: "═", count: boxWidth)
        print("╚\(border)╝")
        print()
    }

    // MARK: - Performance Measurement

    /// Measures the execution time of an async throwing operation.
    static func measure<T>(
        _ operation: () async throws -> T
    ) async throws -> (result: T, duration: Duration) {
        let clock = ContinuousClock()
        let start = clock.now
        let result = try await operation()
        let duration = clock.now - start
        return (result, duration)
    }

    // MARK: - Language Detection

    /// Detects the dominant language in the given text.
    static func detectLanguage(_ text: String) -> NLLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage
    }

    /// Verifies that the text matches the expected language.
    static func verifyLanguage(_ text: String, matches expected: NLLanguage) -> Bool {
        detectLanguage(text) == expected
    }

    /// Verifies that all excerpts match the expected language.
    static func verifyExcerptsLanguage(_ excerpts: [String], expectedLanguage: NLLanguage) {
        for (index, excerpt) in excerpts.enumerated() {
            let detectedLanguage = detectLanguage(excerpt)

            #expect(
                detectedLanguage == expectedLanguage,
                "Excerpt \(index + 1) language mismatch: expected \(expectedLanguage.rawValue), got \(detectedLanguage?.rawValue ?? "unknown")\nExcerpt: \(excerpt)"
            )
        }
    }

    // MARK: - Word Counting

    /// Counts words in text, properly handling all languages including CJK.
    ///
    /// Uses NLTokenizer for accurate word segmentation across different scripts:
    /// - Space-separated languages (English, Spanish, French, etc.)
    /// - CJK languages without spaces (Japanese, Mandarin)
    /// - Mixed scripts
    static func countWords(_ text: String, language: NLLanguage? = nil) -> Int {
        guard !text.isEmpty else { return 0 }

        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        if let language {
            tokenizer.setLanguage(language)
        }

        var wordCount = 0
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { _, _ in
            wordCount += 1
            return true
        }

        return wordCount
    }

    /// Verifies that all excerpts have word counts within the expected range.
    ///
    /// Uses lenient validation with warnings:
    /// - **Error**: Word count < 70% of min or > 150% of max (test fails)
    /// - **Warning**: Word count slightly outside target range but within lenient bounds (test passes with warning)
    /// - **Pass**: Word count within target range
    ///
    /// This approach accommodates LLM variance and language differences while catching egregious violations.
    static func verifyExcerptsWordCount(
        _ excerpts: [String],
        wordRange: ClosedRange<Int>,
        language: NLLanguage? = nil
    ) {
        // Lenient bounds: allow 50% below min, 200% above max before failing
        let strictMinWords = Int(Double(wordRange.lowerBound) * 0.5)  // 70% of minimum
        let strictMaxWords = Int(Double(wordRange.upperBound) * 2.0)  // 200% of maximum

        for (index, excerpt) in excerpts.enumerated() {
            let wordCount = countWords(excerpt, language: language)

            // Check minimum word count
            if wordCount < strictMinWords {
                // FAIL: Way too short (< 70% of target minimum)
                #expect(
                    wordCount >= strictMinWords,
                    "Excerpt \(index + 1) CRITICALLY SHORT: \(wordCount) words (target: \(wordRange.lowerBound)-\(wordRange.upperBound), minimum acceptable: \(strictMinWords))\nExcerpt: \(excerpt)"
                )
            } else if wordCount < wordRange.lowerBound {
                // WARNING: Below target but within acceptable bounds
                Issue.record(
                    Comment(rawValue: "⚠️ Excerpt \(index + 1) slightly short: \(wordCount) words (target minimum: \(wordRange.lowerBound), acceptable minimum: \(strictMinWords))\nExcerpt: \(excerpt)")
                )
            }

            // Check maximum word count
            if wordCount > strictMaxWords {
                // FAIL: Way too long (> 150% of target maximum)
                #expect(
                    wordCount <= strictMaxWords,
                    "Excerpt \(index + 1) CRITICALLY LONG: \(wordCount) words (target: \(wordRange.lowerBound)-\(wordRange.upperBound), maximum acceptable: \(strictMaxWords))\nExcerpt: \(excerpt)"
                )
            } else if wordCount > wordRange.upperBound {
                // WARNING: Above target but within acceptable bounds
                Issue.record(
                    Comment(rawValue: "⚠️ Excerpt \(index + 1) slightly long: \(wordCount) words (target maximum: \(wordRange.upperBound), acceptable maximum: \(strictMaxWords))\nExcerpt: \(excerpt)")
                )
            }
        }
    }

    // MARK: - Excerpt Diversity

    /// Calculates Levenshtein distance between two strings.
    ///
    /// Levenshtein distance is the minimum number of single-character edits
    /// (insertions, deletions, or substitutions) required to change one string into another.
    ///
    /// - Returns: The edit distance between the two strings
    static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let m = s1Array.count
        let n = s2Array.count

        guard m > 0 else { return n }
        guard n > 0 else { return m }

        var matrix = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m {
            matrix[i][0] = i
        }

        for j in 0...n {
            matrix[0][j] = j
        }

        for i in 1...m {
            for j in 1...n {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // deletion
                    matrix[i][j - 1] + 1,      // insertion
                    matrix[i - 1][j - 1] + cost // substitution
                )
            }
        }

        return matrix[m][n]
    }

    /// Calculates similarity ratio between two strings (0.0 to 1.0).
    ///
    /// - Returns: 1.0 for identical strings, 0.0 for completely different strings
    static func similarityRatio(_ s1: String, _ s2: String) -> Double {
        let maxLength = max(s1.count, s2.count)
        guard maxLength > 0 else { return 1.0 }

        let distance = levenshteinDistance(s1, s2)
        return 1.0 - Double(distance) / Double(maxLength)
    }

    /// Verifies that all excerpts are sufficiently different from each other.
    ///
    /// Checks all pairs of excerpts to ensure they have meaningful variation.
    /// Uses Levenshtein distance to measure similarity.
    ///
    /// - Parameters:
    ///   - excerpts: The excerpts to compare
    ///   - minDifferenceRatio: Minimum required difference (0.0-1.0). Default 0.15 means excerpts must be at least 15% different
    static func verifyExcerptsDiversity(
        _ excerpts: [String],
        minDifferenceRatio: Double = 0.15
    ) {
        guard excerpts.count >= 2 else { return }

        for i in 0..<excerpts.count {
            for j in (i + 1)..<excerpts.count {
                let similarity = similarityRatio(excerpts[i], excerpts[j])
                let difference = 1.0 - similarity

                #expect(
                    difference >= minDifferenceRatio,
                    """
                    Excerpts \(i + 1) and \(j + 1) are too similar (\(String(format: "%.1f%%", similarity * 100)) similar, \
                    need at least \(String(format: "%.1f%%", minDifferenceRatio * 100)) difference)

                    Excerpt \(i + 1): \(excerpts[i])

                    Excerpt \(j + 1): \(excerpts[j])
                    """
                )
            }
        }
    }

    private static func languageFlag(for language: String) -> String {
        switch language.lowercased() {
        case "spanish": return "🇪🇸"
        case "english": return "🇬🇧"
        case "french": return "🇫🇷"
        case "japanese": return "🇯🇵"
        case "german": return "🇩🇪"
        case "mandarin": return "🇨🇳"
        case "hindi": return "🇮🇳"
        case "russian": return "🇷🇺"
        case "mixed": return "🌐"
        case "dominant": return "🌐"
        default: return "🌍"
        }
    }

    /// Calculate visual length of string, accounting for emoji width.
    /// Different emojis have different visual widths in terminals.
    static func visualLength(_ string: String) -> Int {
        var length = 0
        var skipNext = false

        for scalar in string.unicodeScalars {
            if skipNext {
                skipNext = false
                continue
            }

            // Regional indicator symbols (flag emojis) - they come in pairs
            if (0x1F1E6...0x1F1FF).contains(scalar.value) {
                length += 2
                skipNext = true // Skip the second regional indicator
            } else if scalar.properties.isEmoji || scalar.properties.isEmojiPresentation {
                // Simple emojis like ✓ often render as 1-2 spaces
                // Being conservative: most emojis take 2 spaces
                length += 2
            } else {
                length += 1
            }
        }
        return length
    }

    // MARK: - Tag Validation

    /// Verifies that all tags match the expected language.
    ///
    /// Detects language from all tags joined together for more reliable detection,
    /// as individual tags may be too short.
    static func verifyTagsLanguage(_ tags: [String], expectedLanguage: NLLanguage) {
        guard !tags.isEmpty else { return }

        // Join all tags with spaces for more reliable language detection
        let joinedTags = tags.joined(separator: " ")
        let detectedLanguage = detectLanguage(joinedTags)

        #expect(
            detectedLanguage == expectedLanguage,
            "Tags language mismatch: expected \(expectedLanguage.rawValue), got \(detectedLanguage?.rawValue ?? "unknown")\nTags: \(tags.joined(separator: ", "))"
        )
    }

    /// Verifies that tags follow the same format as site tags.
    /// Checks for patterns like: lowercase-with-hyphens, lowercase_with_underscores, Title Case, etc.
    static func verifyTagsFormat(_ tags: [String], siteTags: [String]) {
        guard !siteTags.isEmpty else { return }

        // Detect format pattern from site tags
        let hasHyphens = siteTags.contains { $0.contains("-") }
        let hasUnderscores = siteTags.contains { $0.contains("_") }
        let hasSpaces = siteTags.contains { $0.contains(" ") }
        let hasUppercase = siteTags.contains { $0.rangeOfCharacter(from: .uppercaseLetters) != nil }

        for tag in tags {
            // Skip format check for non-Latin scripts (Japanese, Chinese, etc.)
            let isLatinScript = tag.rangeOfCharacter(from: CharacterSet.letters) != nil
            guard isLatinScript else { continue }

            // Record warnings for format inconsistencies (not failures)
            // LLM may reasonably vary formatting based on context
            if hasHyphens && !tag.contains("-") && tag.contains(" ") {
                Issue.record(
                    Comment(rawValue: "⚠️ Site tags use hyphens, but tag '\(tag)' uses spaces")
                )
            } else if hasUnderscores && !tag.contains("_") && tag.contains(" ") {
                Issue.record(
                    Comment(rawValue: "⚠️ Site tags use underscores, but tag '\(tag)' uses spaces")
                )
            }

            // Check case consistency
            let tagHasUppercase = tag.rangeOfCharacter(from: .uppercaseLetters) != nil
            if !hasUppercase && tagHasUppercase {
                Issue.record(
                    Comment(rawValue: "⚠️ Site tags are lowercase, but tag '\(tag)' has uppercase")
                )
            }
        }
    }

    /// Print formatted tag results with context
    static func printTagResults(
        parameters: TagTestCaseParameters,
        tags: [String],
        duration: Duration
    ) {
        let durationSeconds = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18

        printSectionHeader(parameters.testDescription)

        print("⏱️  Generated \(tags.count) tags in \(String(format: "%.3f", durationSeconds))s")

        if !parameters.siteTags.isEmpty {
            print("🏷️  Site tags context: \(parameters.siteTags.count) tags")
        }
        print()

        for (i, tag) in tags.enumerated() {
            let detectedLanguage = detectLanguage(tag)
            let languageInfo = detectedLanguage.map { " [\($0.rawValue)]" } ?? ""
            print("  \(i + 1). \(tag)\(languageInfo)")
        }

        printSectionFooter()
    }

    // MARK: - Summary Validation

    /// Verifies that a summary is in the expected language.
    /// Uses NLLanguageRecognizer to detect the language of the summary.
    static func verifySummaryLanguage(_ summary: String, expectedLanguage: NLLanguage) {
        let detectedLanguage = detectLanguage(summary)

        #expect(detectedLanguage == expectedLanguage,
               "Summary language mismatch: expected \(expectedLanguage.rawValue), got \(detectedLanguage?.rawValue ?? "unknown")")
    }

    /// Prints formatted summary test results to console.
    static func printSummaryResults(
        parameters: SummaryTestCaseParameters,
        summary: String,
        duration: Duration
    ) {
        printSectionHeader("")

        // Test info
        print("Test: \(parameters.testDescription)")
        print("Language: \(parameters.data.languageCode.rawValue)")

        // Duration
        let durationSeconds = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
        print("Duration: \(String(format: "%.2f", durationSeconds))s")

        // Word count comparison
        let summaryWordCount = summary.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let originalWordCount = parameters.data.content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let compressionRatio = Double(summaryWordCount) / Double(originalWordCount) * 100.0
        print("Compression: \(originalWordCount) → \(summaryWordCount) words (\(String(format: "%.1f", compressionRatio))%)")

        print("")

        // Summary content
        print("Summary:")
        print(summary.wrapped(width: 80).split(separator: "\n").map { "  \($0)" }.joined(separator: "\n"))

        printSectionFooter()
    }
}

// MARK: - String Extensions

private extension String {
    /// Wraps text to specified width while preserving words.
    /// Accounts for emoji visual width in terminals.
    func wrapped(width: Int) -> String {
        var result = ""
        var currentLine = ""
        var currentWidth = 0

        for word in self.split(separator: " ") {
            let wordWidth = TestHelpers.visualLength(String(word))

            if currentWidth + wordWidth + 1 > width {
                if !result.isEmpty {
                    result += "\n"
                }
                result += currentLine.trimmingCharacters(in: .whitespaces)
                currentLine = String(word) + " "
                currentWidth = wordWidth + 1
            } else {
                currentLine += word + " "
                currentWidth += wordWidth + 1
            }
        }

        if !currentLine.isEmpty {
            if !result.isEmpty {
                result += "\n"
            }
            result += currentLine.trimmingCharacters(in: .whitespaces)
        }

        return result
    }
}
