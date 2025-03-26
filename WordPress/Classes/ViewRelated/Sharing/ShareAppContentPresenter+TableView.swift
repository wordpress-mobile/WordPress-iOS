import UIKit
import BuildSettingsKit

/// Constants for share app content interoperability with table view.
///
extension ShareAppContentPresenter {
    struct RowConstants {
        static var buttonTitle: String {
            switch BuildSettings.current.brand {
            case .wordpress:
                NSLocalizedString("Share WordPress with a friend", comment: "Title for a button that recommends the app to others")
            case .jetpack:
                NSLocalizedString("Share Jetpack with a friend", comment: "Title for a button that recommends the app to others")
            }
        }

        static let buttonIconImage: UIImage? = .init(systemName: "square.and.arrow.up")
    }
}
