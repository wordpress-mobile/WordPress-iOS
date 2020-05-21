import UIKit
import WordPressShared

@objc open class HomepageSettingsViewController: UITableViewController {

    fileprivate lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    /// Designated Initializer
    ///
    /// - Parameter blog: The blog for which we want to configure Homepage settings
    ///
    @objc public convenience init(blog: Blog) {
        self.init(style: .grouped)
        self.blog = blog
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.title
        clearsSelectionOnViewWillAppear = false

        // Setup tableView
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)

        ImmuTable.registerRows([CheckmarkRow.self, NavigationItemRow.self], tableView: tableView)
        reloadViewModel()
    }

    // MARK: - Model

    fileprivate func reloadViewModel() {
        handler.viewModel = tableViewModel
    }

    fileprivate var tableViewModel: ImmuTable {
        guard let homepageType = blog.homepageType else {
            return ImmuTable(sections: [])
        }

        let blogRow = CheckmarkRow(title: HomepageType.posts.title, checked: homepageType == .posts, action: { _ in
        })

        let pageRow = CheckmarkRow(title: HomepageType.page.title, checked: homepageType == .page, action: { _ in
        })

        let changeTypeSection = ImmuTableSection(headerText: nil,
                                                 rows: [blogRow, pageRow],
                                                 footerText: Strings.footerText)

        let choosePage: ImmuTableAction = { _ in
        }

        let homepageRow = NavigationItemRow(title: Strings.homepage, detail: nil, icon: nil, badgeCount: 0, accessoryType: .disclosureIndicator, action: choosePage, accessibilityIdentifier: nil)
        let postsPageRow = NavigationItemRow(title: Strings.postsPage, detail: nil, icon: nil, badgeCount: 0, accessoryType: .disclosureIndicator, action: choosePage, accessibilityIdentifier: nil)
        let choosePagesSection = ImmuTableSection(headerText: Strings.choosePagesHeaderText, rows: [homepageRow, postsPageRow], footerText: nil)

        var sections = [changeTypeSection]
        if homepageType == .page {
            sections.append(choosePagesSection)
        }

        return ImmuTable(sections: sections)
    }

    // MARK: - Private Properties
    fileprivate var blog: Blog!

    fileprivate enum Strings {
        static let title = NSLocalizedString("Homepage Settings", comment: "Title for the Homepage Settings screen")
        static let footerText = NSLocalizedString("Choose from a homepage that displays your latest posts (classic blog) or a fixed / static page.", comment: "")
        static let homepage = NSLocalizedString("Homepage", comment: "Title for setting which shows the current page assigned as a site's homepage")
        static let postsPage = NSLocalizedString("Posts Page", comment: "Title for setting which shows the current page assigned as a site's posts page")
        static let choosePagesHeaderText = NSLocalizedString("Choose Pages", comment: "Title for settings section which allows user to select their home page and posts page")
    }
}
