import Foundation
import UniformTypeIdentifiers

extension NSURL: ExportableAsset {
    public var assetMediaType: MediaType {
        get {
            guard let contentType = (self as URL).typeIdentifier.flatMap(UTType.init) else {
                return .document
            }
            if contentType.conforms(to: .image) {
                return .image
            }
            if contentType.conforms(to: .video) || contentType.conforms(to: .movie) {
                return .video
            }
            if contentType.conforms(to: .audio) {
                return .audio
            }
            return .document
        }
    }
}
