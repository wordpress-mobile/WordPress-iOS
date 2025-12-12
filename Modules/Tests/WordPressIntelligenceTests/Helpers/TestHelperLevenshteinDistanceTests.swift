import Testing

@Suite("Levenshtein Distance")
struct TestHelperLevenshteinDistanceTests {

    @Test("Identical strings")
    func identicalStrings() {
        let distance = TestHelpers.levenshteinDistance("hello", "hello")
        #expect(distance == 0)

        let similarity = TestHelpers.similarityRatio("hello", "hello")
        #expect(similarity == 1.0)
    }

    @Test("Empty strings")
    func emptyStrings() {
        let distance1 = TestHelpers.levenshteinDistance("", "")
        #expect(distance1 == 0)

        let distance2 = TestHelpers.levenshteinDistance("", "hello")
        #expect(distance2 == 5)

        let distance3 = TestHelpers.levenshteinDistance("hello", "")
        #expect(distance3 == 5)
    }

    @Test("Single character difference")
    func singleCharacterDifference() {
        let distance = TestHelpers.levenshteinDistance("hello", "hallo")
        #expect(distance == 1)

        let similarity = TestHelpers.similarityRatio("hello", "hallo")
        #expect(similarity == 0.8) // 1 change out of 5 characters = 80% similar
    }

    @Test("Insertion")
    func insertion() {
        let distance = TestHelpers.levenshteinDistance("cat", "cats")
        #expect(distance == 1)
    }

    @Test("Deletion")
    func deletion() {
        let distance = TestHelpers.levenshteinDistance("cats", "cat")
        #expect(distance == 1)
    }

    @Test("Substitution")
    func substitution() {
        let distance = TestHelpers.levenshteinDistance("cat", "bat")
        #expect(distance == 1)
    }

    @Test("Multiple operations")
    func multipleOperations() {
        let distance = TestHelpers.levenshteinDistance("kitten", "sitting")
        #expect(distance == 3) // k→s, e→i, insert g
    }

    @Test("Completely different strings")
    func completelyDifferent() {
        let distance = TestHelpers.levenshteinDistance("abc", "xyz")
        #expect(distance == 3)

        let similarity = TestHelpers.similarityRatio("abc", "xyz")
        #expect(similarity == 0.0) // Completely different
    }

    @Test("Case sensitivity")
    func caseSensitivity() {
        let distance = TestHelpers.levenshteinDistance("Hello", "hello")
        #expect(distance == 1) // H→h

        let similarity = TestHelpers.similarityRatio("Hello", "hello")
        #expect(similarity == 0.8) // 1 out of 5 characters different
    }

    @Test("Real excerpt similarity")
    func realExcerptSimilarity() {
        let excerpt1 = "Quantum computing represents a paradigm shift in computation."
        let excerpt2 = "Quantum computing represents a revolutionary shift in computation."

        let similarity = TestHelpers.similarityRatio(excerpt1, excerpt2)
        // "paradigm" → "revolutionary" is a significant change
        // Should be similar but not identical
        #expect(similarity > 0.7 && similarity < 0.95)
    }

    @Test("Very similar excerpts")
    func verySimilarExcerpts() {
        let excerpt1 = "The quick brown fox jumps over the lazy dog."
        let excerpt2 = "The quick brown fox jumps over a lazy dog."
        // Only "the" → "a"

        let similarity = TestHelpers.similarityRatio(excerpt1, excerpt2)
        #expect(similarity > 0.9, "Expected > 90% similarity, got \(similarity)")
    }

    @Test("Sufficiently different excerpts")
    func sufficientlyDifferent() {
        let excerpt1 = "Quantum computing could revolutionize cryptography and drug discovery."
        let excerpt2 = "Traditional computers use bits while quantum systems leverage qubits."

        let similarity = TestHelpers.similarityRatio(excerpt1, excerpt2)
        #expect(similarity < 0.5, "Expected < 50% similarity, got \(similarity)")
    }

    @Test("Verify diversity passes with different excerpts")
    func verifyDiversityPasses() {
        let excerpts = [
            "Quantum computing represents a paradigm shift in how we process information.",
            "Revolutionary quantum systems are transforming computational possibilities.",
            "The future of computing lies in quantum mechanics and superposition."
        ]

        // Should not throw - these are sufficiently different (> 15% difference required)
        TestHelpers.verifyExcerptsDiversity(excerpts)
    }

    @Test("Verify diversity fails with similar excerpts")
    func verifyDiversityFailsWithSimilar() {
        let excerpts = [
            "Quantum computing represents a paradigm shift.",
            "Quantum computing represents a paradigm shift in technology.",
            "Quantum computing represents revolutionary progress."
        ]

        // This test expects the diversity check to fail for very similar excerpts
        // The #expect inside verifyExcerptsDiversity will fail, which is what we're testing
        var didFail = false
        withKnownIssue {
            TestHelpers.verifyExcerptsDiversity(excerpts, minDifferenceRatio: 0.15)
            didFail = true
        }

        // If we get here without the known issue triggering, the diversity check incorrectly passed
        #expect(didFail == false, "Expected diversity check to fail for very similar excerpts")
    }

    @Test("Unicode characters")
    func unicodeCharacters() {
        let distance = TestHelpers.levenshteinDistance("café", "cafe")
        #expect(distance == 1) // é→e

        let distance2 = TestHelpers.levenshteinDistance("日本", "日木")
        #expect(distance2 == 1) // 本→木
    }

    @Test("Emojis")
    func emojis() {
        let distance = TestHelpers.levenshteinDistance("Hello 👋", "Hello 👍")
        #expect(distance == 1) // Different emoji

        let distance2 = TestHelpers.levenshteinDistance("Test 🎉", "Test")
        #expect(distance2 == 2) // Removing emoji (space + emoji)
    }
}
