import Testing
import UniformTypeIdentifiers
import WordPressMediaLibrary
@testable import WordPress

@MainActor
struct MediaDetailShareServiceAdapterFilenameTests {

    private func resolve(
        suggested: String?,
        mimeType: String?,
        sourceUrl: String = "https://example.com/wp-content/uploads/photo.png"
    ) -> String {
        let item = DownloadableMediaItem(
            sourceUrl: URL(string: sourceUrl)!,
            mimeType: mimeType,
            suggestedFilename: suggested
        )
        return MediaDetailShareServiceAdapter.resolveFilename(for: item)
    }

    @Test func dotSegmentTitleGetsMimeExtension() {
        #expect(resolve(suggested: "Logo v2.0", mimeType: "image/png") == "Logo v2.0.png")
    }

    @Test func matchingExtensionIsKept() {
        #expect(resolve(suggested: "photo.jpg", mimeType: "image/jpeg") == "photo.jpg")
        #expect(resolve(suggested: "photo.jpeg", mimeType: "image/jpeg") == "photo.jpeg")
        #expect(resolve(suggested: "PHOTO.JPG", mimeType: "image/jpeg") == "PHOTO.JPG")
    }

    @Test func missingExtensionDerivedFromMimeType() {
        #expect(resolve(suggested: "vacation", mimeType: "image/png") == "vacation.png")
    }

    @Test func missingExtensionFallsBackToSourceURL() {
        #expect(resolve(suggested: "vacation", mimeType: nil) == "vacation.png")
    }

    @Test func dotSegmentTitleWithoutMimeTypeUsesURLExtension() {
        #expect(resolve(suggested: "Logo v2.0", mimeType: nil) == "Logo v2.0.png")
    }

    @Test func mismatchedRealExtensionIsRetyped() {
        #expect(resolve(suggested: "notes.txt", mimeType: "image/png") == "notes.txt.png")
    }

    @Test func genericMimeTypeKeepsRealExtension() {
        #expect(resolve(suggested: "report.pdf", mimeType: "application/octet-stream") == "report.pdf")
    }

    @Test func longNameTruncatesStemAndKeepsExtension() {
        let longStem = String(repeating: "a", count: 250)
        let resolved = resolve(suggested: "\(longStem).jpg", mimeType: "image/jpeg")
        #expect(resolved == "\(String(repeating: "a", count: 200)).jpg")
    }

    @Test func unusableNamesFallBackToMedia() {
        #expect(resolve(suggested: "", mimeType: "image/png") == "media.png")
        #expect(resolve(suggested: ".", mimeType: "image/png") == "media.png")
        #expect(resolve(suggested: "..", mimeType: "image/png") == "media.png")
    }

    @Test func nilSuggestionUsesURLFilename() {
        #expect(resolve(suggested: nil, mimeType: "image/png") == "photo.png")
    }
}
