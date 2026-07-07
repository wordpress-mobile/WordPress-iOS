import Foundation
import Testing

@testable import WordPressMediaLibrary

@Suite("UploadFilenameAllocator")
struct UploadFilenameAllocatorTests {
    // Suites are instantiated per test, so each test gets a fresh allocator.
    private let allocator = UploadFilenameAllocator()

    // MARK: - basename

    @Test("first use of a name returns <stem>.<ext> unchanged")
    func freshNameIsVerbatim() {
        #expect(allocator.basename(stem: "photo", ext: "jpg") == "photo.jpg")
    }

    @Test("repeated names get sequential numeric suffixes")
    func repeatsAreSuffixed() {
        #expect(allocator.basename(stem: "photo", ext: "jpg") == "photo.jpg")
        #expect(allocator.basename(stem: "photo", ext: "jpg") == "photo (2).jpg")
        #expect(allocator.basename(stem: "photo", ext: "jpg") == "photo (3).jpg")
    }

    @Test("the same stem with a different extension does not collide")
    func differentExtensionDoesNotCollide() {
        #expect(allocator.basename(stem: "photo", ext: "jpg") == "photo.jpg")
        #expect(allocator.basename(stem: "photo", ext: "png") == "photo.png")
    }

    @Test("different stems do not collide")
    func differentStemsDoNotCollide() {
        #expect(allocator.basename(stem: "a", ext: "jpg") == "a.jpg")
        #expect(allocator.basename(stem: "b", ext: "jpg") == "b.jpg")
    }

    @Test("deduplication state is scoped to a single allocator instance")
    func dedupIsPerInstance() {
        #expect(UploadFilenameAllocator().basename(stem: "photo", ext: "jpg") == "photo.jpg")
        // A separate allocator starts with a clean slate, so no suffix.
        #expect(UploadFilenameAllocator().basename(stem: "photo", ext: "jpg") == "photo.jpg")
    }

    // MARK: - stem derivation

    @Test(
        "preferred names sanitize to filesystem-safe stems",
        arguments: [
            ("My Vacation", "My Vacation"), // usable names are kept verbatim
            ("a/b/c", "a_b_c"), // path separators become underscores
            ("///", "___"), // separator-only names sanitize, not fall back
            ("a\u{0}b", "ab"), // NUL characters are stripped
            (String(repeating: "a", count: 300), String(repeating: "a", count: 256)) // capped at 256
        ]
    )
    func preferredNameSanitization(preferred: String, expected: String) {
        #expect(allocator.stem(preferred: preferred, fallbackPrefix: "Photo", date: Date()) == expected)
    }

    @Test("a nil preferred name falls back to a filesystem-safe <prefix>-<timestamp>")
    func nilFallsBackToPrefixTimestamp() {
        let stem = allocator.stem(preferred: nil, fallbackPrefix: "Photo", date: Date())
        // Digits, dashes, and a space only, so the generated timestamp is
        // filesystem-safe (no ":" or "/") by construction.
        let pattern = #"^Photo-\d{4}-\d{2}-\d{2} \d{2}-\d{2}-\d{2}$"#
        #expect(stem.range(of: pattern, options: .regularExpression) != nil)
    }

    @Test("an empty preferred name falls back to the prefix")
    func emptyFallsBackToPrefix() {
        let stem = allocator.stem(preferred: "", fallbackPrefix: "Video", date: Date())
        #expect(stem.hasPrefix("Video-"))
    }

    // MARK: - end-to-end

    @Test("a source name flows through to a complete upload basename")
    func sourceNameBecomesBasename() {
        let stem = allocator.stem(preferred: "Quarterly Report", fallbackPrefix: "File", date: Date())
        #expect(allocator.basename(stem: stem, ext: "pdf") == "Quarterly Report.pdf")
    }
}
