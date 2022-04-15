
import UIKit

/// Site Name screen for the Site Creation flow
class SiteNameViewController: UIViewController {

    private let siteNameViewFactory: () -> UIView
    private let onView: () -> Void
    private let onSkip: () -> Void
    private let onCancel: () -> Void

    init(
        siteNameViewFactory: @escaping () -> UIView,
        onView: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.siteNameViewFactory = siteNameViewFactory
        self.onView = onView
        self.onSkip = onSkip
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = siteNameViewFactory()
        setTitleForTraitCollection()
        configureNavigationBar()

    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setTitleForTraitCollection()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.becomeFirstResponder()
        onView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isMovingFromParent {
            // Called when popping from a nav controller, e.g. hitting "Back"
            onCancel()
        }
    }
}

// MARK: Navigation Bar
private extension SiteNameViewController {

    func configureNavigationBar() {
        removeNavigationBarBorder()
        // Add skip button
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: TextContent.skipButtonTitle,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(skipButtonTapped))
    }

    @objc
    private func skipButtonTapped() {
        onSkip()
    }

    /// Removes the separator line at the bottom of the navigation bar
    func removeNavigationBarBorder() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.backgroundColor = .basicBackground
        navBarAppearance.shadowColor = .clear
        navBarAppearance.shadowImage = UIImage()
        navigationItem.standardAppearance = navBarAppearance
        navigationItem.scrollEdgeAppearance = navBarAppearance
        navigationItem.compactAppearance = navBarAppearance
        setNeedsStatusBarAppearanceUpdate()
    }
}

// MARK: Title
private extension SiteNameViewController {

    // hides or shows the title depending on the vertical size class ands accessibility category
    func setTitleForTraitCollection() {
        title = (traitCollection.verticalSizeClass == .compact ||
                 traitCollection.preferredContentSizeCategory.isAccessibilityCategory) ?
        TextContent.titleForVerticalCompactSizeClass :
        ""
    }
}

// MARK: Constants
private extension SiteNameViewController {

    enum TextContent {
        static let titleForVerticalCompactSizeClass = NSLocalizedString("Give your website a name",
                                                                        comment: "Title for Site Name screen in iPhone landscape.")
        static let skipButtonTitle = NSLocalizedString("Skip",
                                                       comment: "Title for the Skip button in the Site Name Screen.")
    }
}
