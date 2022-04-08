
import UIKit

/// Site Name screen for the Site Creation flow
class SiteNameViewController: UIViewController {

    private let creator: SiteCreator

    var nameView: SiteNameView {
        return view as! SiteNameView
    }

    private var verticalTitle: String? {
        guard let vertical = creator.vertical else {
            return nil
        }

        return vertical.localizedTitle
    }

    init(creator: SiteCreator) {
        self.creator = creator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = SiteNameView()
        removeNavigationBarBorder()
        setTitleForTraitCollection()

    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setTitleForTraitCollection()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        nameView.setTitle(verticalTitle: verticalTitle)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.becomeFirstResponder()
    }
}

// MARK: Convenience methods and properties
private extension SiteNameViewController {

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

    // hides or show title depending on the vertical size class ands accessibility category
    func setTitleForTraitCollection() {
        title = (traitCollection.verticalSizeClass == .compact ||
                 traitCollection.preferredContentSizeCategory.isAccessibilityCategory) ?
        Self.titleForVerticalCompactSizeClass :
        ""
    }

    static let titleForVerticalCompactSizeClass = NSLocalizedString("Give your website a name",
                                                                    comment: "Title for Site Name screen in iPhone landscape.")
}
