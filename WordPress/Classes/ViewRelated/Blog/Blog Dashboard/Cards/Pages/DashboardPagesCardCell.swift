import UIKit

final class DashboardPagesCardCell: DashboardCollectionViewCell {

    private var blog: Blog?
    private weak var presentingViewController: BlogDashboardViewController?

    // MARK: - Views

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.title = Strings.title
        return frameView
    }()

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup

    private func setupView() {
        contentView.addSubview(cardFrameView)
        contentView.pinSubviewToAllEdges(cardFrameView, priority: .defaultHigh)
    }

    // MARK: - BlogDashboardCardConfigurable

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog
        self.presentingViewController = viewController

        configureContextMenu(blog: blog)

        // FIXME: configure card using api response
        // Expecting a list of pages
    }

    // MARK: Context Menu

    private func configureContextMenu(blog: Blog) {
        cardFrameView.onEllipsisButtonTap = {
            BlogDashboardAnalytics.trackContextualMenuAccessed(for: .pages)
        }
        cardFrameView.ellipsisButton.showsMenuAsPrimaryAction = true

        let children = [makeAllPagesAction(blog: blog), makeHideCardAction(blog: blog)].compactMap { $0 }

        cardFrameView.ellipsisButton.menu = UIMenu(title: String(), options: .displayInline, children: children)
    }

    private func makeAllPagesAction(blog: Blog) -> UIMenuElement {
        let allPagesAction = UIAction(title: Strings.allPages,
                                      image: Style.allPagesImage,
                                      handler: { _ in self.showPagesList(for: blog) })

        // Wrap the activity action in a menu to display a divider between the activity action and hide this action.
        // https://developer.apple.com/documentation/uikit/uimenu/options/3261455-displayinline
        let allPagesSubmenu = UIMenu(title: String(), options: .displayInline, children: [allPagesAction])
        return allPagesSubmenu
    }

    private func makeHideCardAction(blog: Blog) -> UIMenuElement? {
        guard let siteID = blog.dotComID?.intValue else {
            return nil
        }
        return BlogDashboardHelpers.makeHideCardAction(for: .pages, siteID: siteID)
    }

    // MARK: Actions

    private func showPagesList(for blog: Blog) {
        guard let presentingViewController else {
            return
        }
        PageListViewController.showForBlog(blog, from: presentingViewController)
    }
}

extension DashboardPagesCardCell {

    static func shouldShowCard(for blog: Blog) -> Bool {
        guard RemoteFeatureFlag.pagesDashboardCard.enabled(),
              blog.supports(.pages) else {
            return false
        }

        return true
    }
}

extension DashboardPagesCardCell {

    private enum Strings {
        static let title = NSLocalizedString("dashboardCard.Pages.title",
                                             value: "Pages",
                                             comment: "Title for the Pages dashboard card.")
        static let allPages = NSLocalizedString("dashboardCard.Pages.contextMenu.allPages",
                                                   value: "All Pages",
                                                   comment: "Title for an action that opens the full pages list.")
    }

    private enum Style {
        static let allPagesImage = UIImage(systemName: "doc.text")
    }
}
