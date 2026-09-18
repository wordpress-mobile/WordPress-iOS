import Foundation
import Photos
import Testing
import UniformTypeIdentifiers

@testable import WordPress

/// Covers the resource the loader picks out of an asset. Getting this wrong is silent —
/// the upload succeeds, it just carries the wrong file (an unedited original, or the
/// video half of a Live Photo).
struct PhotoLibraryFileLoaderResourceTests {

    // MARK: - Photos

    /// An edited photo carries both the render and the untouched original. The render is
    /// what the picker itself would have produced, so it's what gets uploaded.
    @Test func prefersTheEditedRenditionOverTheOriginalPhoto() {
        let index = PhotoLibraryFileLoader.preferredResourceIndex(
            in: [.photo, .adjustmentData, .fullSizePhoto],
            mediaType: .image
        )
        #expect(index == 2)
    }

    /// An unedited photo has no `.fullSizePhoto`, so the original is the only rendition.
    @Test func fallsBackToTheOriginalPhotoWhenThereIsNoEditedRendition() {
        let index = PhotoLibraryFileLoader.preferredResourceIndex(in: [.photo], mediaType: .image)
        #expect(index == 0)
    }

    /// A Live Photo is an image asset that also carries the video half. Matching on the
    /// asset's media type keeps the still image from being swapped for the movie.
    @Test func picksTheStillImageOfALivePhoto() {
        let index = PhotoLibraryFileLoader.preferredResourceIndex(
            in: [.pairedVideo, .photo],
            mediaType: .image
        )
        #expect(index == 1)
    }

    // MARK: - Videos

    @Test func prefersTheEditedRenditionOverTheOriginalVideo() {
        let index = PhotoLibraryFileLoader.preferredResourceIndex(
            in: [.video, .fullSizeVideo],
            mediaType: .video
        )
        #expect(index == 1)
    }

    @Test func fallsBackToTheOriginalVideoWhenThereIsNoEditedRendition() {
        let index = PhotoLibraryFileLoader.preferredResourceIndex(in: [.video], mediaType: .video)
        #expect(index == 0)
    }

    /// A video asset should never be uploaded as one of its still frames.
    @Test func neverPicksAPhotoResourceForAVideo() {
        let types: [PHAssetResourceType] = [.photo, .fullSizePhoto, .video]
        let index = PhotoLibraryFileLoader.preferredResourceIndex(in: types, mediaType: .video)
        #expect(index == 2)
    }

    // MARK: - Fallbacks

    /// Nothing matched, so the first resource is the best guess — the same one the picker
    /// would have handed over.
    @Test func fallsBackToTheFirstResourceWhenNoPreferredTypeIsPresent() {
        let index = PhotoLibraryFileLoader.preferredResourceIndex(
            in: [.adjustmentData, .adjustmentBasePhoto],
            mediaType: .unknown
        )
        #expect(index == 0)
    }

    @Test func returnsNilWhenTheAssetHasNoResources() {
        #expect(PhotoLibraryFileLoader.preferredResourceIndex(in: [], mediaType: .image) == nil)
    }

    // MARK: - Preference order

    @Test func preferenceOrderIsScopedToTheAssetsMediaType() {
        #expect(PhotoLibraryFileLoader.preferredResourceTypes(for: .image) == [.fullSizePhoto, .photo, .alternatePhoto])
        #expect(PhotoLibraryFileLoader.preferredResourceTypes(for: .video) == [.fullSizeVideo, .video])
        #expect(PhotoLibraryFileLoader.preferredResourceTypes(for: .audio) == [.audio])
        #expect(PhotoLibraryFileLoader.preferredResourceTypes(for: .unknown).isEmpty)
    }
}

/// Covers the switch that decides whether a picked item is read from the photo library or
/// from the item provider.
struct ItemProviderMediaExporterSourceTests {

    /// Outside Lockdown Mode the item provider stays the route even when the picker was
    /// library-backed and supplied an asset identifier.
    @Test func usesTheItemProviderWhenThePhotoLibrarySourceIsNotPreferred() async throws {
        let exporter = try makeExporter(assetIdentifier: "any-identifier")
        exporter.prefersPhotoLibrarySource = false

        let media = try await exporter.export()

        #expect(media.url.pathExtension == "jpeg")
        MediaExporterTests.cleanUpExportedMedia(atURL: media.url)
    }

    /// The asset can't be resolved, and the two routes are exclusive: retrying through
    /// the item provider is pointless in Lockdown Mode — it's the thing that can't serve
    /// the file — so the failure is reported instead of being silently papered over.
    @Test func reportsAFailureRatherThanFallingBackWhenTheAssetCannotBeResolved() async throws {
        let exporter = try makeExporter(assetIdentifier: "not-a-real-asset/L0/001")
        exporter.prefersPhotoLibrarySource = true

        await #expect(throws: ItemProviderMediaExporter.ExportError.self) {
            try await exporter.export()
        }
    }

    /// Without an asset identifier there is nothing to look up, so the item provider is
    /// the only route even under Lockdown Mode.
    @Test func usesTheItemProviderWhenThereIsNoAssetIdentifier() async throws {
        let exporter = try makeExporter(assetIdentifier: nil)
        exporter.prefersPhotoLibrarySource = true

        let media = try await exporter.export()

        #expect(media.url.pathExtension == "jpeg")
        MediaExporterTests.cleanUpExportedMedia(atURL: media.url)
    }

    private func makeExporter(assetIdentifier: String?) throws -> ItemProviderMediaExporter {
        let imageURL = try #require(Bundle.test.url(forResource: "iphone-photo", withExtension: "heic"))
        let provider = NSItemProvider()
        provider.registerFileRepresentation(forTypeIdentifier: UTType.heic.identifier, visibility: .all) { completion in
            completion(imageURL, false, nil)
            return nil
        }
        let exporter = ItemProviderMediaExporter(provider: provider, assetIdentifier: assetIdentifier)
        exporter.mediaDirectoryType = .temporary
        return exporter
    }
}
