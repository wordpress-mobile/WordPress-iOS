import Testing
import UniformTypeIdentifiers
import WordPressData
import WordPressMediaLibrary
@testable import WordPress

@MainActor
struct ExternalRemoteMediaAdapterTests {

    @Test func stockPhotos_prefersAssetNameOverURLStem() {
        let asset = StubExternalMediaAsset(
            id: "1",
            name: "Sunset over the harbor",
            caption: "by Foo",
            largeURL: URL(string: "https://images.pexels.com/photos/1234/pexels-photo.jpg")!,
            thumbnailURL: URL(string: "https://example.com/thumb.jpg")!
        )
        let media = ExternalRemoteMedia(stockPhotosAsset: asset)
        #expect(media.suggestedName == "Sunset over the harbor")
        #expect(media.contentType == .jpeg)
        #expect(media.caption == "by Foo")
    }

    @Test func stockPhotos_fallsBackToDefault_whenNameAndURLStemAreEmpty() {
        let asset = StubExternalMediaAsset(
            id: "p2",
            name: "",
            caption: "",
            largeURL: URL(string: "https://images.pexels.com/")!,
            thumbnailURL: URL(string: "https://example.com/")!
        )
        let media = ExternalRemoteMedia(stockPhotosAsset: asset)
        #expect(media.suggestedName == "External Media")
    }
}

/// Simple test stub for `ExternalMediaAsset` (a V1 app-target protocol
/// inheriting from `AnyObject` + `ExportableAsset` which is
/// `NSObjectProtocol`). Lives in this test file only.
private final class StubExternalMediaAsset: NSObject, ExternalMediaAsset {
    let id: String
    let name: String
    let caption: String
    let largeURL: URL
    let thumbnailURL: URL
    var assetMediaType: MediaType { .image }
    init(id: String, name: String, caption: String, largeURL: URL, thumbnailURL: URL) {
        self.id = id
        self.name = name
        self.caption = caption
        self.largeURL = largeURL
        self.thumbnailURL = thumbnailURL
        super.init()
    }
}
