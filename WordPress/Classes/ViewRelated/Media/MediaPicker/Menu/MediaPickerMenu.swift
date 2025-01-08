import UIKit

/// A convenience API for creating actions for picking media from different
/// source supported by the app: Photos library, Camera, Media library.
struct MediaPickerMenu {
    weak var presentingViewController: UIViewController?
    var filter: MediaFilter?
    var isMultipleSelectionEnabled: Bool
    var initialSelection: [Media]

    enum MediaFilter {
        case images
        case videos
    }

    /// Initializes the options.
    ///
    /// - parameters:
    ///   - viewController: The view controller to use for presentation.
    ///   - filter: By default, `nil` – allow all content types.
    ///   - isMultipleSelectionEnabled: By default, `false`.
    ///   - initialSelection: By default, `[]`.
    init(viewController: UIViewController,
         filter: MediaFilter? = nil,
         isMultipleSelectionEnabled: Bool = false,
         initialSelection: [Media] = []) {
        self.presentingViewController = viewController
        self.filter = filter
        self.isMultipleSelectionEnabled = isMultipleSelectionEnabled
        self.initialSelection = initialSelection
    }
}

extension MediaPickerMenu.MediaFilter {
    init?(_ mediaType: WPMediaType) {
        switch mediaType {
        case .image: self = .images
        case .video: self = .videos
        default: return nil
        }
    }

    var mediaType: MediaType {
        switch self {
        case .images: return .image
        case .videos: return .video
        }
    }
}
