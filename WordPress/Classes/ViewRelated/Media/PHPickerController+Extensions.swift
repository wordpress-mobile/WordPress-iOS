import UIKit
import PhotosUI
import UniformTypeIdentifiers

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
        NSItemProvider.loadImage(for: result.itemProvider, completion)
    }
}

extension NSItemProvider {
    // MARK: - Images

    @MainActor
    static func image(for result: NSItemProvider) async throws -> UIImage {
        try await withUnsafeThrowingContinuation { continuation in
            NSItemProvider.loadImage(for: result) { image, error in
                if let image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: error ?? URLError(.unknown))
                }
            }
        }
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

    // MARK: - Videos

    /// Exports video to the given URL.
    ///
    /// - returns: Returns a location of the exported file in the temporary directory.
    @MainActor
    static func video(for provider: NSItemProvider) async throws -> URL {
        return try await withUnsafeThrowingContinuation { continuation in
            provider.loadFileRepresentation(forTypeIdentifier: UTType.data.identifier) { url, error in
                guard let url else {
                    continuation.resume(throwing: error ?? URLError(.unknown))
                    return
                }
                do {
                    // important: The video has to be copied as it's get deleted
                    // the moment this function returns.
                    let copyURL = getTemporaryFolderURL()
                        .appendingPathComponent(url.lastPathComponent)
                        .incrementalFilename()
                    try FileManager.default.moveItem(at: url, to: copyURL)
                    continuation.resume(returning: copyURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    static func removeTemporaryData() {
        try? FileManager.default.removeItem(at: temporaryFolderURL)
    }
}

private let temporaryFolderURL = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("org.automattic.NSItemProvider", isDirectory: true)

private func getTemporaryFolderURL() -> URL {
    let folderURL = temporaryFolderURL
    try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
    return folderURL
}
