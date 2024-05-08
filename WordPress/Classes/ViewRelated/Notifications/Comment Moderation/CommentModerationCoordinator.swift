import UIKit
import WordPressUI
import SwiftUI

final class CommentModerationCoordinator {
    private let presentingViewController: UIViewController

    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
    }

    func didTapMoreOptions() {
        let hostingController = UIHostingController(rootView: CommentModerationOptionsView())
        let bottomSheet = BottomSheetViewController(childViewController: hostingController, customHeaderSpacing: 0)
        bottomSheet.show(from: presentingViewController)
    }
}

extension UIHostingController: DrawerPresentable {
    public var allowsUserTransition: Bool {
        false
    }
    
    /// Due to using `UIHostingController` in `BottomSheetViewController` the most practical
    /// way to calculate height here was to scale it with `UIFontMetrics` since `intrinsicContentSize`
    /// does not work here.
    public var collapsedHeight: DrawerHeight {
        let metrics = UIFontMetrics(forTextStyle: .body)
        let scaleMultiplier = metrics.scaledValue(for: 1)

        return .contentHeight(CommentModerationOptionsView.estimatedHeight * scaleMultiplier)
    }
}
