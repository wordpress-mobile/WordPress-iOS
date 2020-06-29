import UIKit

protocol PrepublishingDismissible {
    func handleDismiss()
}

class PrepublishingNavigationController: LightNavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the height for iPad
        if UIDevice.isPad() {
            preferredContentSize = Constants.iPadPreferredContentSize
        }
    }

    private enum Constants {
        static let height: CGFloat = 290
        static let iPadPreferredContentSize = CGSize(width: 300, height: 240)
    }
}


// MARK: - DrawerPresentable

extension PrepublishingNavigationController: DrawerPresentable {
    var allowsUserTransition: Bool {
        return false
    }

    var expandedHeight: DrawerHeight {
        return .topMargin(20)
    }

    var collapsedHeight: DrawerHeight {
        return .contentHeight(Constants.height)
    }

    var scrollableView: UIScrollView? {
        let scroll = topViewController?.view as? UIScrollView

        return scroll
    }

    func handleDismiss() {
        if let rootViewController = viewControllers.first as? PrepublishingDismissible {
            rootViewController.handleDismiss()
        }
    }
}
