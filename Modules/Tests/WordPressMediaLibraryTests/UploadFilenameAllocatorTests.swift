import Foundation
import Testing

@testable import WordPressMediaLibrary

@Suite("UploadFilenameAllocator")
struct UploadFilenameAllocatorTests {

    // MARK: - basename

    @Test("first use of a name returns <stem>.<ext> unchanged")
    func freshNameIsVerbatim() {
        let allocator = UploadFilenameAllocator()
        #expect(allocator.basename(stem: "photo", ext: "jpg") == "photo.jpg")
    }

    @Test("repeated names get sequential numeric suffixes")
    func repeatsAreSuffixed() {
        let allocator = UploadFilenameAllocator()
        #expect(allocator.basename(stem: "photo", ext: "jpg") == "photo.jpg")
        #expect(allocator.basename(stem: "photo", ext: "jpg") == "photo (2).jpg")
        #expect(allocator.basename(stem: "photo", ext: "jpg") == "photo (3).jpg")
    }

    @Test("the same stem with a different extension does not collide")
    func differentExtensionDoesNotCollide() {
        let allocator = UploadFilenameAllocator()
        #expect(allocator.basename(stem: "photo", ext: "jpg") == "photo.jpg")
        #expect(allocator.basename(stem: "photo", ext: "png") == "photo.png")
    }

    @Test("different stems do not collide")
    func differentStemsDoNotCollide() {
        let allocator = UploadFilenameAllocator()
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

    @Test("a usable preferred name is kept as the stem")
    func preferredNameIsKept() {
        let allocator = UploadFilenameAllocator()
        #expect(
            allocator.stem(preferred: "My Vacation", fallbackPrefix: "Photo", date: Date()) == "My Vacation"
        )
    }

    @Test("path separators in the preferred name become underscores")
    func slashesAreReplaced() {
        let allocator = UploadFilenameAllocator()
        #expect(allocator.stem(preferred: "a/b/c", fallbackPrefix: "Photo", date: Date()) == "a_b_c")
    }

    @Test("a name made only of separators sanitizes to underscores, not a fallback")
    func onlySeparatorsBecomeUnderscores() {
        let allocator = UploadFilenameAllocator()
        #expect(allocator.stem(preferred: "///", fallbackPrefix: "Photo", date: Date()) == "___")
    }

    @Test("NUL characters are stripped from the preferred name")
    func nulIsStripped() {
        let allocator = UploadFilenameAllocator()
        #expect(allocator.stem(preferred: "a\u{0}b", fallbackPrefix: "Photo", date: Date()) == "ab")
    }

    @Test("an over-long preferred name is capped at 256 characters")
    func longNameIsCapped() {
        let allocator = UploadFilenameAllocator()
        let stem = allocator.stem(
            preferred: String(repeating: "a", count: 300),
            fallbackPrefix: "Photo",
            date: Date()
        )
        #expect(stem == String(repeating: "a", count: 256))
    }

    @Test("a nil preferred name falls back to a filesystem-safe <prefix>-<timestamp>")
    func nilFallsBackToPrefixTimestamp() {
        let allocator = UploadFilenameAllocator()
        let stem = allocator.stem(preferred: nil, fallbackPrefix: "Photo", date: Date())
        let pattern = #"^Photo-\d{4}-\d{2}-\d{2} \d{2}-\d{2}-\d{2}$"#
        #expect(stem.range(of: pattern, options: .regularExpression) != nil)
        // The generated timestamp must be filesystem-safe.
        #expect(!stem.contains(":"))
        #expect(!stem.contains("/"))
    }

    @Test("an empty preferred name falls back to the prefix")
    func emptyFallsBackToPrefix() {
        let allocator = UploadFilenameAllocator()
        let stem = allocator.stem(preferred: "", fallbackPrefix: "Video", date: Date())
        #expect(stem.hasPrefix("Video-"))
    }

    // MARK: - end-to-end

    @Test("a source name flows through to a complete upload basename")
    func sourceNameBecomesBasename() {
        let allocator = UploadFilenameAllocator()
        let stem = allocator.stem(preferred: "Quarterly Report", fallbackPrefix: "File", date: Date())
        #expect(allocator.basename(stem: stem, ext: "pdf") == "Quarterly Report.pdf")
    }
}
