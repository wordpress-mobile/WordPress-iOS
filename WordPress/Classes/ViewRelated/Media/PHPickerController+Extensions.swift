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
