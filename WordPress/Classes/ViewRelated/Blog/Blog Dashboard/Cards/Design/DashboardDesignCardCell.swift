import UIKit
import WordPressData
import WordPressShared
import WordPressUI

/// Offers a starter design to a blank site that this app install created through the short site creation flow.
final class DashboardDesignCardCell: DashboardCollectionViewCell {
    private let frameView = BlogDashboardCardFrameView()
    private weak var presentingViewController: BlogDashboardViewController?
    private var blog: Blog?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFrameView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Hiding the card or applying a design removes the site from the record, so there is no personalization
    /// setting to check.
    static func shouldShowCard(for blog: Blog, isJetpack: Bool, record: BlankSiteRecord = BlankSiteRecord()) -> Bool {
        guard isJetpack, let siteID = blog.dotComID?.intValue else {
            return false
        }
        return record.contains(siteID: siteID)
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog
        self.presentingViewController = viewController
        BlogDashboardAnalytics.shared.track(.designCardShown, blog: blog)
    }

    private func setupFrameView() {
        frameView.setTitle(DashboardDesignCardView.Strings.title)
        let cardView = DashboardDesignCardView { [weak self] in
            self?.showDesignPicker()
        }
        frameView.add(subview: UIHostingView(view: cardView))
        frameView.onViewTap = { [weak self] in
            self?.showDesignPicker()
        }
        let hideAction = BlogDashboardHelpers.makeHideCardAction { [weak self] in
            self?.hideCard()
        }
        frameView.addMoreMenu(items: [hideAction], card: .design)
        frameView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(frameView)
        contentView.pinSubviewToAllEdges(frameView, priority: .defaultHigh)
    }

    private func showDesignPicker() {
        guard let blog, let presentingViewController else {
            return
        }
        WPAnalytics.track(.designCardTapped, blog: blog)
        StarterDesignPickerCoordinator.start(for: blog, from: presentingViewController) {
            [weak presentingViewController] in
            presentingViewController?.reloadCardsLocally()
        }
    }

    private func hideCard() {
        guard let blog, let siteID = blog.dotComID?.intValue else {
            return
        }
        BlogDashboardAnalytics.trackHideTapped(for: .design)
        WPAnalytics.track(.designCardHidden, blog: blog)
        BlankSiteRecord().remove(siteID: siteID)
        presentingViewController?.reloadCardsLocally()
    }
}
