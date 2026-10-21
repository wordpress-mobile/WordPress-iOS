import UIKit
import WordPressShared

/// Shares the Reader's content navigation across all window sizes.
@MainActor
final class AdaptiveReaderNavigation {
    let presenter = ReaderPresenter()
    let tab: UITab

    init() {
        let navigationController = presenter.prepareForTabBarPresentation()
        tab = UITab(
            title: SharedStrings.Reader.title,
            image: UIImage(systemName: "eyeglasses"),
            identifier: "reader"
        ) { _ in navigationController }
        tab.preferredPlacement = .fixed
        tab.accessibilityIdentifier = "tabbar_reader"
    }
}
