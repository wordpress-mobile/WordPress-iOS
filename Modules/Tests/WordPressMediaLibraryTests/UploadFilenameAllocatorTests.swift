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
            ("a\u{0}b", "ab") // NUL characters are stripped
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

    // MARK: - basename safety

    @Test("basename neutralizes a traversing stem into a single path component")
    func basenameNeutralizesTraversal() {
        // The `/` is replaced, so the result can't climb out of its parent dir
        // via `appendingPathComponent`. `basename` sanitizes even when the
        // caller (`.remoteURL`, `.imagePlayground`) skipped `stem`.
        #expect(allocator.basename(stem: "../escaped", ext: "jpg") == ".._escaped.jpg")
    }

    @Test("basename caps an over-long ASCII stem within NAME_MAX")
    func basenameCapsLongASCIIStem() {
        let basename = allocator.basename(stem: String(repeating: "a", count: 400), ext: "jpg")
        #expect(basename.utf8.count <= 255)
        #expect(basename.hasSuffix(".jpg"))
    }

    @Test("basename caps a multibyte stem on a grapheme boundary")
    func basenameCapsMultibyteStem() {
        // "あ" is 3 UTF-8 bytes, so a naive byte-slice could split it. The cap
        // must stay within NAME_MAX and never leave a broken scalar behind.
        let basename = allocator.basename(stem: String(repeating: "あ", count: 300), ext: "jpg")
        #expect(basename.utf8.count <= 255)
        #expect(basename.hasSuffix(".jpg"))
        // No replacement character: every retained scalar is intact.
        #expect(!basename.contains("\u{FFFD}"))
    }

    @Test("a stem that sanitizes to empty falls back to a stub basename")
    func emptyStemFallsBackToStub() {
        #expect(allocator.basename(stem: "", ext: "jpg") == "file.jpg")
        #expect(allocator.basename(stem: "\u{0}", ext: "png") == "file.png")
    }

    @Test("truncated stems still deduplicate and stay within NAME_MAX")
    func truncatedStemsDeduplicate() {
        let stem = String(repeating: "a", count: 400)
        let first = allocator.basename(stem: stem, ext: "jpg")
        let second = allocator.basename(stem: stem, ext: "jpg")
        #expect(first != second)
        #expect(second.contains(" (2)"))
        #expect(second.utf8.count <= 255)
    }

    // MARK: - end-to-end

    @Test("a source name flows through to a complete upload basename")
    func sourceNameBecomesBasename() {
        let stem = allocator.stem(preferred: "Quarterly Report", fallbackPrefix: "File", date: Date())
        #expect(allocator.basename(stem: stem, ext: "pdf") == "Quarterly Report.pdf")
    }
}
