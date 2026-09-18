import Foundation
import Photos
import PhotosUI
import UIKit
import WordPressData

/// A media item picked from the device's Photos library.
///
/// The two pickers the app presents hand back different things, and this is what they
/// have in common. Outside Lockdown Mode `PHPickerViewController` gives an
/// `NSItemProvider`; under Lockdown Mode the legacy picker gives a `PHAsset`, which is
/// carried here as its local identifier so `ItemProviderMediaExporter` can read the file
/// straight from the library. See `PhotosPickerPresenter` for why they differ.
final class PhotosPickerAsset: NSObject, ExportableAsset {
    /// The picker's item provider. `nil` for an item picked with the legacy picker, which
    /// vends assets rather than providers.
    let itemProvider: NSItemProvider?

    /// The local identifier of the backing `PHAsset`, when the picker supplied one.
    let assetIdentifier: String?

    let assetMediaType: MediaType

    init(itemProvider: NSItemProvider?, assetIdentifier: String?, assetMediaType: MediaType) {
        self.itemProvider = itemProvider
        self.assetIdentifier = assetIdentifier
        self.assetMediaType = assetMediaType
    }

    convenience init(_ result: PHPickerResult) {
        self.init(
            itemProvider: result.itemProvider,
            assetIdentifier: result.assetIdentifier,
            assetMediaType: result.itemProvider.assetMediaType
        )
    }

    convenience init(_ asset: PHAsset) {
        self.init(
            itemProvider: nil,
            assetIdentifier: asset.localIdentifier,
            assetMediaType: MediaType(asset.mediaType)
        )
    }
}

extension PhotosPickerAsset {
    /// Retrieves an image for the item, for the flows that crop one rather than upload it.
    ///
    /// Prefers the photo library when the item came from there, both because it's the only
    /// source the legacy picker gives us and because the item provider can't materialize a
    /// large photo under Lockdown Mode — see `PhotoLibraryFileLoader`.
    ///
    /// - parameter completion: Called on the main thread.
    func loadImage(_ completion: @escaping (UIImage?, Error?) -> Void) {
        guard let assetIdentifier, itemProvider == nil || LockdownHelper.isDeviceLockdownModeEnabled else {
            return loadImageFromItemProvider(completion)
        }
        PhotoLibraryFileLoader.loadImage(assetIdentifier: assetIdentifier) { [self] image in
            guard let image else {
                return loadImageFromItemProvider(completion)
            }
            DispatchQueue.main.async {
                completion(image, nil)
            }
        }
    }

    private func loadImageFromItemProvider(_ completion: @escaping (UIImage?, Error?) -> Void) {
        guard let itemProvider else {
            return DispatchQueue.main.async { completion(nil, nil) }
        }
        NSItemProvider.loadImage(for: itemProvider, completion)
    }
}

private extension MediaType {
    init(_ mediaType: PHAssetMediaType) {
        switch mediaType {
        case .image: self = .image
        case .video: self = .video
        case .audio: self = .audio
        default: self = .document
        }
    }
}
