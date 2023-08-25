import UIKit
import PhotosUI

extension PHPickerConfiguration {
    /// Returns the picker configuration optimized for the Jetpack app.
    static func make() -> PHPickerConfiguration {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.preferredAssetRepresentationMode = .compatible
        configuration.selection = .ordered
        configuration.selectionLimit = 0 // Unlimited
        return configuration
    }
}

extension PHPickerFilter {
    init?(_ type: WPMediaType) {
        switch type {
        case .image:
            self = .images
        case .video:
            self = .videos
        case .audio, .other:
            assertionFailure("Unsupported media type: \(type)")
            return nil
        case .all:
            return nil
        default:
            return nil
        }
    }
}

extension PHPickerResult {
    /// Retrieves an image for the given picker result.
    ///
    /// - parameter completion: The completion closure that gets called on the main thread.
    static func loadImage(for result: PHPickerResult, _ completion: @escaping (UIImage?, Error?) -> Void) {
        loadImage(for: result.itemProvider, completion)
    }

    /// Retrieves an image for the given picker result.
    ///
    /// - parameter completion: The completion closure that gets called on the main thread.
    static func loadImage(for provider: NSItemProvider, _ completion: @escaping (UIImage?, Error?) -> Void) {
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { value, error in
                DispatchQueue.main.async {
                    if let image = value as? UIImage {
                        completion(image, nil)
                    } else {
                        DDLogError("Failed to load image for provider with registered types \(provider.registeredTypeIdentifiers) with error \(String(describing: error))")

                        completion(nil, error)
                    }
                }
            }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            // This is required for certain image formats, such as WebP, for which
            // NSItemProvider doesn't automatically provide the `UIImage` representation.
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                let image = data.flatMap(UIImage.init)
                DispatchQueue.main.async {
                    if let image {
                        completion(image, nil)
                    } else {
                        DDLogError("Failed to load image for provider with registered types \(provider.registeredTypeIdentifiers) with error \(String(describing: error))")
                        completion(nil, error)
                    }
                }
            }
        } else {
            DDLogError("No image representation available for provider with registered types: \(provider.registeredTypeIdentifiers)")
            DispatchQueue.main.async {
                completion(nil, nil)
            }
        }
    }
}
