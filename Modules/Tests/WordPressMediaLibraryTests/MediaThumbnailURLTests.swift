import Testing
import WordPressAPI
import WordPressAPIInternal
@testable import WordPressMediaLibrary

struct MediaThumbnailURLTests {
    private func detailsWithSizes(_ sizes: [String: ScaledImageDetails]?) -> ImageMediaDetails {
        ImageMediaDetails(fileSize: 0, width: 0, height: 0, file: "x.jpg", sizes: sizes)
    }

    private func scaled(_ urlString: String) -> ScaledImageDetails {
        // ScaledImageDetails init signature: file / width / height / sourceUrl
        // (no mimeType).
        ScaledImageDetails(file: "x", width: 0, height: 0, sourceUrl: urlString)
    }

    @Test func picksMediumWhenPresent() {
        let details = detailsWithSizes([
            "thumbnail": scaled("https://example.com/thumb.jpg"),
            "medium": scaled("https://example.com/medium.jpg"),
            "large": scaled("https://example.com/large.jpg")
        ])
        let url = MediaThumbnailURL.pick(from: details, sourceUrl: "https://example.com/original.jpg")
        #expect(url?.absoluteString == "https://example.com/medium.jpg")
    }

    @Test func picksMediumLargeWhenMediumIsAbsent() {
        let details = detailsWithSizes([
            "thumbnail": scaled("https://example.com/thumb.jpg"),
            "medium_large": scaled("https://example.com/medium-large.jpg"),
            "large": scaled("https://example.com/large.jpg")
        ])
        let url = MediaThumbnailURL.pick(from: details, sourceUrl: "https://example.com/original.jpg")
        #expect(url?.absoluteString == "https://example.com/medium-large.jpg")
    }

    @Test func picksLargeWhenMediumAndMediumLargeAreAbsent() {
        let details = detailsWithSizes([
            "thumbnail": scaled("https://example.com/thumb.jpg"),
            "large": scaled("https://example.com/large.jpg")
        ])
        let url = MediaThumbnailURL.pick(from: details, sourceUrl: "https://example.com/original.jpg")
        #expect(url?.absoluteString == "https://example.com/large.jpg")
    }

    @Test func picksThumbnailWhenItIsTheOnlyPreferredSize() {
        let details = detailsWithSizes([
            "thumbnail": scaled("https://example.com/thumb.jpg")
        ])
        let url = MediaThumbnailURL.pick(from: details, sourceUrl: "https://example.com/original.jpg")
        #expect(url?.absoluteString == "https://example.com/thumb.jpg")
    }

    @Test func fallsBackToSourceUrlWhenSizesIsNil() {
        let details = detailsWithSizes(nil)
        let url = MediaThumbnailURL.pick(from: details, sourceUrl: "https://example.com/original.jpg")
        #expect(url?.absoluteString == "https://example.com/original.jpg")
    }

    @Test func fallsBackToSourceUrlWhenNoPreferredKeyMatches() {
        let details = detailsWithSizes([
            "custom-size": scaled("https://example.com/custom.jpg")
        ])
        let url = MediaThumbnailURL.pick(from: details, sourceUrl: "https://example.com/original.jpg")
        #expect(url?.absoluteString == "https://example.com/original.jpg")
    }

    @Test func returnsNilWhenAllUrlsAreMalformed() {
        let details = detailsWithSizes([
            "medium": scaled("")
        ])
        let url = MediaThumbnailURL.pick(from: details, sourceUrl: "")
        #expect(url == nil)
    }
}
