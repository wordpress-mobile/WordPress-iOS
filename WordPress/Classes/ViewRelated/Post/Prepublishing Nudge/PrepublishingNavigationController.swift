import UIKit


class PrepublishingNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()


        configureNavigationBar()

        // Set the height for iPad
        if UIDevice.isPad() {
            view.heightAnchor.constraint(equalToConstant: Constants.height).isActive = true
        }
    }

    private func configureNavigationBar() {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
//            appearance.backgroundColor = .white

            navigationBar.standardAppearance = appearance
            
        } else {
            let clearImage = UIImage(color: .clear, havingSize: CGSize(width: 1, height: 1))
            navigationBar.shadowImage = clearImage
        }
    }

    private enum Constants {
        static let height: CGFloat = 300
    }
}


// MARK: - DrawerPresentable

extension PrepublishingNavigationController: DrawerPresentable {
    var expandedHeight: DrawerHeight {
        return .topMargin(20)
    }

    var collapsedHeight: DrawerHeight {
        return .contentHeight(Constants.height)
    }

    var scrollableView: UIScrollView? {
        let scroll = visibleViewController?.view as? UIScrollView

        return scroll
    }
}
