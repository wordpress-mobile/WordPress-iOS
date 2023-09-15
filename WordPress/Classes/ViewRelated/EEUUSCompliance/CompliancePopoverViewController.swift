import UIKit
import SwiftUI
import WordPressUI

final class CompliancePopoverViewController: UIHostingController<CompliancePopover> {

    // MARK: - Dependencies

    private let viewModel: CompliancePopoverViewModel
    private var bannerIntrinsicHeight: CGFloat = 0

    init(viewModel: CompliancePopoverViewModel) {
        self.viewModel = viewModel
        super.init(rootView: CompliancePopover(viewModel: viewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Make the banner scrollable when the banner height is bigger than the screen height.
        // Send it in the next run loop to avoid a recursive `viewDidLayoutSubviews`.
        if bannerIntrinsicHeight == 0 {
            bannerIntrinsicHeight = view.intrinsicContentSize.height + Length.Padding.small
            DispatchQueue.main.async {
                self.rootView.shouldScroll = self.bannerIntrinsicHeight > self.view.frame.height
            }
        }
    }
}

// MARK: - DrawerPresentable
extension CompliancePopoverViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        return .contentHeight(bannerIntrinsicHeight)
    }

    var expandedHeight: DrawerHeight {
        return .contentHeight(bannerIntrinsicHeight)
    }

    var allowsUserTransition: Bool {
        return false
    }

    var allowsDragToDismiss: Bool {
        false
    }

    var allowsTapToDismiss: Bool {
        return false
    }
}
