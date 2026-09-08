import Foundation
import Photos
import UIKit
import UniformTypeIdentifiers

/// Reads a picked photo-library asset directly from the library, bypassing the system's
/// `PhotosFileProvider` extension.
///
/// The app normally gets picked media from the `NSItemProvider` vended by
/// `PHPickerViewController`, which is served by that extension. Under iOS Lockdown Mode
/// the extension performs a hardened full decode when it materializes an image and gets
/// killed at its 20 MB memory limit, so large photos can't be imported at all — a 36 MP
/// image needs roughly `36e6 × 4` bytes, or ~144 MB. The cost tracks megapixels, not file
/// size; videos stream without a decode and are unaffected in either mode.
///
/// `PHAssetResourceManager` and `PHImageManager` are serviced by `photolibraryd`, which
/// has no such cap — the same 36 MP original streams to disk in tens of milliseconds.
/// They need Photos authorization and an asset identifier from a library-backed picker,
/// which is why the app only takes this route under Lockdown Mode. See
/// `PhotosPickerPresenter` for the picker side and `ItemProviderMediaExporter` for the
/// upload side.
enum PhotoLibraryFileLoader {
    enum LoaderError: Error, CustomStringConvertible {
        /// The picked asset couldn't be resolved in the library.
        ///
        /// Carries the app's Photos authorization, because that's usually the reason:
        /// under `.limited`, an asset the picker let the user choose but that they never
        /// granted the app access to doesn't resolve here.
        case assetNotFound(authorization: PHAuthorizationStatus)
        /// The asset has no resource attached to it.
        case resourceNotFound

        var description: String {
            switch self {
            case .assetNotFound(let authorization):
                return "assetNotFound(authorization: \(authorization.name))"
            case .resourceNotFound:
                return "resourceNotFound"
            }
        }
    }

    /// A file streamed out of the photo library.
    struct LoadedFile {
        let url: URL
        /// The type of the streamed resource, e.g. `public.heic`. Describes the file on
        /// disk, which isn't necessarily the type the item provider would have produced.
        let typeIdentifier: String
    }

    // MARK: - Streaming the original file

    /// Streams the file backing `assetIdentifier` into `directory`, calling `completion`
    /// on an arbitrary queue.
    ///
    /// Throws — without starting any work — when the asset or a resource to stream can't
    /// be resolved, so the caller can fall back to the item provider.
    ///
    /// - parameter progress: Updated as the file streams. Cancelling it doesn't stop the
    ///   request (`PHAssetResourceManager` gives no way to cancel a write), but the
    ///   caller can use it to tell a cancellation apart from a genuine failure.
    static func loadFile(
        assetIdentifier: String,
        into directory: URL,
        progress: Progress,
        completion: @escaping (Result<LoadedFile, Error>) -> Void
    ) throws {
        guard let asset = fetchAsset(withIdentifier: assetIdentifier) else {
            throw LoaderError.assetNotFound(authorization: PHPhotoLibrary.authorizationStatus(for: .readWrite))
        }
        let resources = PHAssetResource.assetResources(for: asset)
        guard let index = preferredResourceIndex(in: resources.map(\.type), mediaType: asset.mediaType) else {
            throw LoaderError.resourceNotFound
        }
        let resource = resources[index]
        let fileURL = directory.appendingPathComponent(filename(for: resource))

        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true // The original may still live in iCloud
        options.progressHandler = { fraction in
            progress.completedUnitCount = Int64(fraction * Double(progress.totalUnitCount))
        }
        Loggers.app.info("Streaming picked asset \(resource.type.rawValue) resource from the photo library")
        PHAssetResourceManager.default()
            .writeData(for: resource, toFile: fileURL, options: options) { error in
                if let error {
                    completion(.failure(error))
                } else {
                    progress.completedUnitCount = progress.totalUnitCount
                    completion(.success(LoadedFile(url: fileURL, typeIdentifier: resource.uniformTypeIdentifier)))
                }
            }
    }

    /// The resource types to look for, most preferred first, for an asset of `mediaType`.
    ///
    /// The `fullSize` variants are the *current* rendition of an edited asset and only
    /// exist once it has been edited; the plain variants are the untouched original.
    /// Preferring the former uploads an edited photo with its edits, which is what the
    /// picker produces with `preferredAssetRepresentationMode = .current`.
    static func preferredResourceTypes(for mediaType: PHAssetMediaType) -> [PHAssetResourceType] {
        switch mediaType {
        case .image: return [.fullSizePhoto, .photo, .alternatePhoto]
        case .video: return [.fullSizeVideo, .video]
        case .audio: return [.audio]
        default: return []
        }
    }

    /// The index of the resource to stream, or `nil` when the asset has no resources.
    ///
    /// Matching on the asset's own media type keeps a Live Photo — which carries both a
    /// `.photo` and a `.pairedVideo` resource — from uploading the wrong half. When none
    /// of the preferred types are present the first resource is used, which is the best
    /// guess available.
    static func preferredResourceIndex(in types: [PHAssetResourceType], mediaType: PHAssetMediaType) -> Int? {
        for preferred in preferredResourceTypes(for: mediaType) {
            if let index = types.firstIndex(of: preferred) {
                return index
            }
        }
        return types.isEmpty ? nil : 0
    }

    /// A safe name for the streamed file.
    ///
    /// `originalFilename` is metadata carried by the library, so it's reduced to its last
    /// path component to keep it from escaping the staging directory.
    static func filename(for resource: PHAssetResource) -> String {
        let filename = (resource.originalFilename as NSString).lastPathComponent
        guard !filename.isEmpty, filename != ".", filename != ".." else {
            let fileExtension = UTType(resource.uniformTypeIdentifier)?.preferredFilenameExtension
            return fileExtension.map { "media.\($0)" } ?? "media"
        }
        return filename
    }

    // MARK: - Loading a display image

    /// The largest image the app asks the library for.
    ///
    /// Everything on this path crops the result down to a site icon or an avatar, so a
    /// full-resolution decode would be wasted work — and would reintroduce the memory
    /// cost this type exists to avoid, just in the app instead of the extension.
    private static let maximumImageSize = CGSize(width: 2048, height: 2048)

    /// Loads a display-ready image for `assetIdentifier`, or `nil` when the library can't
    /// produce one. Calls `completion` on an arbitrary queue.
    static func loadImage(assetIdentifier: String, completion: @escaping (UIImage?) -> Void) {
        guard let asset = fetchAsset(withIdentifier: assetIdentifier) else {
            return completion(nil)
        }
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true // The original may still live in iCloud
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        PHImageManager.default()
            .requestImage(
                for: asset,
                targetSize: maximumImageSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                // `.highQualityFormat` delivers a single, final result, so there's no
                // degraded placeholder to filter out here.
                completion(image)
            }
    }

    // MARK: - Helpers

    private static func fetchAsset(withIdentifier identifier: String) -> PHAsset? {
        let options = PHFetchOptions()
        // Left unset, the source types are inferred from the query, which for a fetch by
        // local identifier means the user's own library only. The picker will happily
        // hand over an asset that came from an iCloud Shared Album or an iTunes sync, so
        // ask for all three rather than let those fall through to the item provider.
        options.includeAssetSourceTypes = [.typeUserLibrary, .typeCloudShared, .typeiTunesSynced]
        return PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: options).firstObject
    }
}

private extension PHAuthorizationStatus {
    /// A readable name for logs; the raw values alone are hard to read back.
    var name: String {
        switch self {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorized: return "authorized"
        case .limited: return "limited"
        @unknown default: return "unknown(\(rawValue))"
        }
    }
}
