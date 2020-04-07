import UIKit


class PrepublishingNavigationController: UINavigationController {

    lazy var header: PrepublishingHeaderView = {
        let header = PrepublishingHeaderView.loadFromNib()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.delegate = self
        return header
    }()

    lazy var blog: Blog? = {
        return (viewControllers.first { $0 is PrepublishingViewController } as? PrepublishingViewController)?.post.blog
    }()


    private func updateAdditionalAreaInsets() {
        var top: CGFloat = 0

        // In iOS 13+ we need to take into account the navigationBar frame height
        // iOS 12 or 11 that's not needed
        if #available(iOS 13, *) {
            top = Constants.navigationHeaderHeight - navigationBar.frame.height
        } else {
            top = Constants.navigationHeaderHeight
        }

        let insets = UIEdgeInsets(top: top, left: 0, bottom: 0, right: 0)

        additionalSafeAreaInsets = insets
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        configureNavigationHeader()
        configureNavigationBar()

        // Set the height for iPad
        if UIDevice.isPad() {
            view.heightAnchor.constraint(equalToConstant: Constants.height).isActive = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let blog = blog else {
            return
        }

        // Configure the header
        header.configure(blog)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateAdditionalAreaInsets()
    }

    private func configureNavigationBar() {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            navigationBar.standardAppearance = appearance
        } else {
            let clearImage = UIImage(color: .clear, havingSize: CGSize(width: 1, height: 1))
            navigationBar.shadowImage = clearImage
        }
    }

    private func configureNavigationHeader() {
        view.addSubview(header)

        // Put our custom navigation in front of the current navigation
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leftAnchor.constraint(equalTo: navigationBar.leftAnchor),
            header.rightAnchor.constraint(equalTo: navigationBar.rightAnchor),
            header.heightAnchor.constraint(equalToConstant: Constants.navigationHeaderHeight)
        ])
    }

    private enum Constants {
        static let navigationHeaderHeight: CGFloat = 80
        static let height: CGFloat = 300
    }
}

// MARK: - UINavigationControllerDelegate

extension PrepublishingNavigationController: UINavigationControllerDelegate {

    /// Animated the back button based on what View Controller will be shown
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        transitionCoordinator?.animate(alongsideTransition: { context in
            if viewController is PrepublishingViewController {
                self.header.hideBackButton()
                self.header.hideTitle()
            } else {
                self.header.showBackButton()
                self.header.showTitle()
            }

            self.header.setTitle(viewController.title, transitionDuration: context.transitionDuration)
        }, completion: nil)
    }
}

// MARK: - PrepublishingHeaderViewDelegate

extension PrepublishingNavigationController: PrepublishingHeaderViewDelegate {

    /// Pop the current view controller when Back button is pressed
    func backButtonTapped() {
        popViewController(animated: true)
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
