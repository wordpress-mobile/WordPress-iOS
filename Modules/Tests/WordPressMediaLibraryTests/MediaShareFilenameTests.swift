import Testing
@testable import WordPressMediaLibrary

@Suite("MediaShareFilename.suggested")
struct MediaShareFilenameTests {
    // Primitive form, both call sites (grid VM + detail VM) flow through this.
    @Test func primitives_returnsTrimmedTitleWhenPresent() {
        #expect(
            MediaShareFilename.suggested(
                title: "  My Photo  ",
                slug: "ignored",
                sourceUrl: "https://example.com/image.jpg",
                id: 1
            ) == "My Photo"
        )
    }

    @Test func primitives_fallsBackToSlugWhenTitleBlank() {
        #expect(
            MediaShareFilename.suggested(
                title: "   ",
                slug: "  my-slug  ",
                sourceUrl: "https://example.com/image.jpg",
                id: 1
            ) == "my-slug"
        )
    }

    @Test func primitives_fallsBackToLastPathComponentWhenTitleAndSlugBlank() {
        #expect(
            MediaShareFilename.suggested(
                title: nil,
                slug: "",
                sourceUrl: "https://example.com/2024/05/IMG_1234.jpg",
                id: 1
            ) == "IMG_1234.jpg"
        )
    }

    @Test func primitives_fallsBackToMediaIdWhenNothingElseAvailable() {
        #expect(MediaShareFilename.suggested(title: nil, slug: "", sourceUrl: "", id: 42) == "media-42")
    }

    // Convenience overload, forwards to the primitive helper from a `MediaWithEditContext`.
    @Test func forMedia_forwardsToTitle() {
        let media = makeMediaFixture(titleRaw: "Vacation", slug: "ignored", sourceUrl: "https://example.com/image.jpg")
        #expect(MediaShareFilename.suggested(for: media) == "Vacation")
    }

    @Test func forMedia_forwardsToSlugFallback() {
        let media = makeMediaFixture(
            titleRaw: "   ",
            slug: "  vacation-photo  ",
            sourceUrl: "https://example.com/image.jpg"
        )
        #expect(MediaShareFilename.suggested(for: media) == "vacation-photo")
    }

    @Test func forMedia_forwardsToSourceUrlFallback() {
        let media = makeMediaFixture(titleRaw: nil, slug: "", sourceUrl: "https://example.com/2024/05/IMG_1234.jpg")
        #expect(MediaShareFilename.suggested(for: media) == "IMG_1234.jpg")
    }

    @Test func forMedia_forwardsToMediaIdFallback() {
        let media = makeMediaFixture(id: 42, titleRaw: nil, slug: "", sourceUrl: "")
        #expect(MediaShareFilename.suggested(for: media) == "media-42")
    }

    // Filesystem-special candidate rejection. Title and slug are
    // user-controlled site data and could literally be "." or "..". Without
    // rejection, the share path would append them as path components and
    // moveItem would fail (NSCocoaErrorDomain 516).

    @Test func primitives_rejectsDotTitle_fallsBackToSlug() {
        #expect(
            MediaShareFilename.suggested(title: ".", slug: "my-slug", sourceUrl: "https://example.com/IMG_1.jpg", id: 1)
                == "my-slug"
        )
    }

    @Test func primitives_rejectsDotDotTitle_fallsBackToSlug() {
        #expect(
            MediaShareFilename.suggested(
                title: "..",
                slug: "my-slug",
                sourceUrl: "https://example.com/IMG_1.jpg",
                id: 1
            ) == "my-slug"
        )
    }

    @Test func primitives_rejectsDotSlug_fallsBackToUrlLastComponent() {
        #expect(
            MediaShareFilename.suggested(
                title: nil,
                slug: ".",
                sourceUrl: "https://example.com/2024/05/IMG_1.jpg",
                id: 1
            ) == "IMG_1.jpg"
        )
    }

    @Test func primitives_rejectsDotDotSlug_fallsBackToUrlLastComponent() {
        #expect(
            MediaShareFilename.suggested(
                title: nil,
                slug: "..",
                sourceUrl: "https://example.com/2024/05/IMG_1.jpg",
                id: 1
            ) == "IMG_1.jpg"
        )
    }

    @Test func primitives_rejectsAllSpecialComponents_fallsBackToMediaId() {
        #expect(MediaShareFilename.suggested(title: ".", slug: "..", sourceUrl: "", id: 42) == "media-42")
    }

    @Test func primitives_rejectsWhitespaceWrappedDot_fallsBackToSlug() {
        // Title is trimmed before the special-component check, so " . " is
        // first reduced to "." and then rejected.
        #expect(MediaShareFilename.suggested(title: " . ", slug: "my-slug", sourceUrl: "", id: 1) == "my-slug")
    }
}
