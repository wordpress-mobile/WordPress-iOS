import UIKit
import UniformTypeIdentifiers

extension NSItemProvider: ExportableAsset {
    public var assetMediaType: MediaType {
        if hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            return .image
        } else if hasItemConformingToTypeIdentifier(UTType.video.identifier) ||
                    hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            return .video
        } else {
            return .document
        }
    }
}

extension NSItemProvider {
    func hasConformingType(_ type: UTType) -> Bool {
        hasItemConformingToTypeIdentifier(type.identifier)
    }
}
