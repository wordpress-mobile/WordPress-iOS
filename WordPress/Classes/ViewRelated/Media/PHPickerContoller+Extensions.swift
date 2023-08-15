import UIKit
import PhotosUI

extension PHPickerConfiguration {
    /// Returns the picker configuration optimized for the Jetpack app.
    static func make() -> PHPickerConfiguration {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.preferredAssetRepresentationMode = .compatible
        configuration.selection = .ordered
        configuration.selectionLimit = 100
        return configuration
    }
}
