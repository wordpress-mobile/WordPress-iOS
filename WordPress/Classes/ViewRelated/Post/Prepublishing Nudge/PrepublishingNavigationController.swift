import UIKit

class PrepublishingNavigationController: UINavigationController, BottomSheetPresentable {
    var initialHeight: CGFloat = 200

    lazy var header: PrepublishingHeaderView = {
        let header = PrepublishingHeaderView.loadFromNib()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.delegate = self
        return header
    }()

    lazy var blog: Blog? = {
        return (viewControllers.first { $0 is PrepublishingViewController } as? PrepublishingViewController)?.post.blog
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        configureNavigationHeader()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let blog = blog else {
            return
        }

        // Configure the header
        header.configure(blog)
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
        additionalSafeAreaInsets = UIEdgeInsets(top: Constants.navigationHeaderHeight - navigationBar.frame.height, left: 0, bottom: 0, right: 0)
    }

    private enum Constants {
        static let navigationHeaderHeight: CGFloat = 80
    }
}

// MARK: - UINavigationControllerDelegate

extension PrepublishingNavigationController: UINavigationControllerDelegate {

    /// Animated the back button based on what View Controller will be shown
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        transitionCoordinator?.animate(alongsideTransition: { context in
            viewController is PrepublishingViewController ? self.header.hideBackButton() : self.header.showBackButton()
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

typealias UIBottomSheetPresentable = BottomSheetPresentable & UIViewController

protocol BottomSheetPresentable {
    var initialHeight: CGFloat { get }
}
