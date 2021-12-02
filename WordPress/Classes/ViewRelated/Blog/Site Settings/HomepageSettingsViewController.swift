import UIKit
import WordPressFlux
import WordPressShared

@objc open class HomepageSettingsViewController: UITableViewController {

    fileprivate enum PageSelectionType {
        case homepage
        case postsPage

        var title: String {
            switch self {
            case .homepage:
                return Strings.homepage
            case .postsPage:
                return Strings.postsPage
            }
        }

        var pickerTitle: String {
            switch self {
            case .homepage:
                return Strings.homepagePicker
            case .postsPage:
                return Strings.postsPagePicker
            }
        }

        var publishedPostsOnly: Bool {
            switch self {
            case .homepage:
                return true
            case .postsPage:
                return false
            }
        }
    }

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

        let context = blog.managedObjectContext ?? ContextManager.shared.mainContext
        postService = PostService(managedObjectContext: context)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.title
        clearsSelectionOnViewWillAppear = false

        // Setup tableView
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)

        ImmuTable.registerRows([CheckmarkRow.self, NavigationItemRow.self, ActivityIndicatorRow.self], tableView: tableView)
        reloadViewModel()

        fetchAllPages()
    }

    private func fetchAllPages() {
        let options = PostServiceSyncOptions()
        options.number = 20

        postService.syncPosts(ofType: .page, with: options, for: blog, success: { [weak self] posts in
            self?.reloadViewModel()
        }, failure: { _ in

        })
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateDeselectionInteractively()
    }

    // MARK: - Model

    fileprivate func reloadViewModel() {
        handler.viewModel = tableViewModel
    }

    fileprivate var tableViewModel: ImmuTable {
        guard let homepageType = blog.homepageType else {
            return ImmuTable(sections: [])
        }

        let homepageRows: [ImmuTableRow]
        if case .homepageType = inProgressChange {
            homepageRows = updatingHomepageTypeRows
        } else {
            homepageRows = homepageTypeRows
        }

        let changeTypeSection = ImmuTableSection(headerText: nil,
                                                 rows: homepageRows,
                                                 footerText: Strings.footerText)

        let choosePagesSection = ImmuTableSection(headerText: Strings.choosePagesHeaderText, rows: selectedPagesRows)

        var sections = [changeTypeSection]
        if homepageType == .page {
            sections.append(choosePagesSection)
        }

        return ImmuTable(sections: sections)
    }

    // MARK: - Table Rows

    var updatingHomepageTypeRows: [ImmuTableRow] {
        guard let homepageType = blog.homepageType else {
            return []
        }

        return [
            ActivityIndicatorRow(title: HomepageType.posts.title, animating: homepageType == .posts, action: nil),
            ActivityIndicatorRow(title: HomepageType.page.title, animating: homepageType == .page, action: nil)
        ]
    }

    var homepageTypeRows: [ImmuTableRow] {
        guard let homepageType = blog.homepageType else {
            return []
        }

        return [
            CheckmarkRow(title: HomepageType.posts.title, checked: homepageType == .posts, action: { [weak self] _ in
                if self?.inProgressChange == nil {
                    self?.update(with: .homepageType(.posts))
                }
            }),
            CheckmarkRow(title: HomepageType.page.title, checked: homepageType == .page, action: { [weak self] _ in
                if self?.inProgressChange == nil {
                    self?.update(with: .homepageType(.page))
                }
            })
        ]
    }

    var selectedPagesRows: [ImmuTableRow] {
        let homepageID = blog.homepagePageID
        let homepage = homepageID.flatMap { postService.findPost(withID: NSNumber(value: $0), in: blog) }
        let homepageTitle = homepage?.titleForDisplay() ?? ""

        let postsPageID = blog.homepagePostsPageID
        let postsPage = postsPageID.flatMap { postService.findPost(withID: NSNumber(value: $0), in: blog) }
        let postsPageTitle = postsPage?.titleForDisplay() ?? ""

        let homepageRow = pageSelectionRow(selectionType: .homepage,
                                                      detail: homepageTitle,
                                                      selectedPostID: blog?.homepagePageID,
                                                      hiddenPostID: blog?.homepagePostsPageID,
                                                      isInProgress: HomepageChange.isSelectedHomepage,
                                                      changeForPost: { .selectedHomepage($0) })
        let postsPageRow = pageSelectionRow(selectionType: .postsPage,
                                                       detail: postsPageTitle,
                                                       selectedPostID: blog?.homepagePostsPageID,
                                                       hiddenPostID: blog?.homepagePageID,
                                                       isInProgress: HomepageChange.isSelectedPostsPage,
                                                       changeForPost: { .selectedPostsPage($0) })
        return [homepageRow, postsPageRow]
    }

    private func pageSelectionRow(selectionType: PageSelectionType,
                                          detail: String,
                                          selectedPostID: Int?,
                                          hiddenPostID: Int?,
                                          isInProgress: (HomepageChange) -> Bool,
                                          changeForPost: @escaping (Int) -> HomepageChange) -> ImmuTableRow {
        if let inProgressChange = inProgressChange, isInProgress(inProgressChange) {
            return ActivityIndicatorRow(title: selectionType.title, animating: true, action: nil)
        } else {
            return NavigationItemRow(title: selectionType.title, detail: detail, action: { [weak self] _ in
                self?.showPageSelection(selectionType: selectionType, selectedPostID: selectedPostID, hiddenPostID: hiddenPostID, change: changeForPost)
            })
        }
    }

    // MARK: - Page Selection Navigation

    private func showPageSelection(selectionType: PageSelectionType, selectedPostID: Int?, hiddenPostID: Int?, change: @escaping (Int) -> HomepageChange) {
        pushPageSelection(selectionType: selectionType, selectedPostID: selectedPostID, hiddenPostID: hiddenPostID) { [weak self] selected in
            if let postID = selected.postID?.intValue {
                self?.update(with: change(postID))
            }
        }
    }

    fileprivate func pushPageSelection(selectionType: PageSelectionType, selectedPostID: Int?, hiddenPostID: Int?, _ completion: @escaping (Page) -> Void) {
        let hiddenPosts: [Int]
        if let postID = hiddenPostID {
            hiddenPosts = [postID]
        } else {
            hiddenPosts = []
        }
        let viewController = SelectPostViewController(blog: blog,
                                                      isSelectedPost: { $0.postID?.intValue == selectedPostID },
                                                      showsPostType: false,
                                                      entityName: Page.entityName(),
                                                      hiddenPosts: hiddenPosts,
                                                      publishedOnly: selectionType.publishedPostsOnly,
                                                      callback: { [weak self] (post) in
            if let page = post as? Page {
                completion(page)
            }
            self?.navigationController?.popViewController(animated: true)
        })
        viewController.title = selectionType.pickerTitle
        navigationController?.pushViewController(viewController, animated: true)
    }

    // MARK: - Remote Updating

    /// The options for changing a homepage
    /// Note: This is mapped to the actual property changes in `update(with change:)`
    private enum HomepageChange {
        case homepageType(HomepageType)
        case selectedHomepage(Int)
        case selectedPostsPage(Int)

        static func isHomepageType(_ change: HomepageChange) -> Bool {
            if case .homepageType = change { return true } else { return false }
        }

        static func isSelectedHomepage(_ change: HomepageChange) -> Bool {
            if case .selectedHomepage = change { return true } else { return false }
        }

        static func isSelectedPostsPage(_ change: HomepageChange) -> Bool {
            if case .selectedPostsPage = change { return true } else { return false }
        }
    }

    /// Sends the remote service call to update `blog` homepage settings properties.
    /// - Parameter change: The change to update for `blog`.
    private func update(with change: HomepageChange) {
        guard inProgressChange == nil else {
                return
        }

        /// Configure `blog` properties for the remote call
        let homepageType: HomepageType
        var homepagePostsPageID = blog.homepagePostsPageID
        var homepagePageID = blog.homepagePageID

        switch change {
        case .homepageType(let type):
            homepageType = type
        case .selectedPostsPage(let id):
            homepageType = .page
            homepagePostsPageID = id
        case .selectedHomepage(let id):
            homepageType = .page
            homepagePageID = id
        }

        /// If the blog hasn't changed, don't waste time saving it.
        guard blog.homepageType != homepageType ||
                blog.homepagePostsPageID != homepagePostsPageID ||
                blog.homepagePageID != homepagePageID else { return }

        inProgressChange = change

        /// If there is already an in progress change (i.e. bad network), don't push the view controller and deselect the selection immediately.
        tableView.allowsSelection = false

        WPAnalytics.trackSettingsChange("homepage_settings",
                                        fieldName: "homepage_type",
                                        value: (homepageType == .page) ? "page" : "posts")

        /// Send the remove service call
        let service = HomepageSettingsService(blog: blog, context: blog.managedObjectContext!)
        service?.setHomepageType(homepageType,
                                 withPostsPageID: homepagePostsPageID,
                                 homePageID: homepagePageID,
                                 success: { [weak self] in
            self?.endUpdating()
        }, failure: { [weak self] error in
            self?.endUpdating()

            let notice = Notice(title: Strings.updateErrorTitle, message: Strings.updateErrorMessage, feedbackType: .error)
            ActionDispatcher.global.dispatch(NoticeAction.post(notice))
        })

        reloadViewModel()
    }

    fileprivate func endUpdating() {
        inProgressChange = nil
        tableView.allowsSelection = true
        reloadViewModel()
    }

    // MARK: - Private Properties
    fileprivate var blog: Blog!

    fileprivate var postService: PostService!

    /// Are we currently updating the homepage type?
    private var inProgressChange: HomepageChange? = nil

    fileprivate enum Strings {
        static let title = NSLocalizedString("Homepage Settings", comment: "Title for the Homepage Settings screen")
        static let footerText = NSLocalizedString("Choose from a homepage that displays your latest posts (classic blog) or a fixed / static page.", comment: "Explanatory text for Homepage Settings homepage type selection.")
        static let homepage = NSLocalizedString("Homepage", comment: "Title for setting which shows the current page assigned as a site's homepage")
        static let homepagePicker = NSLocalizedString("Choose Homepage", comment: "Title for selecting a new homepage")
        static let postsPage = NSLocalizedString("Posts Page", comment: "Title for setting which shows the current page assigned as a site's posts page")
        static let postsPagePicker = NSLocalizedString("Choose Posts Page", comment: "Title for selecting a new posts page")
        static let choosePagesHeaderText = NSLocalizedString("Choose Pages", comment: "Title for settings section which allows user to select their home page and posts page")
        static let updateErrorTitle = NSLocalizedString("Unable to update homepage settings", comment: "Error informing the user that their homepage settings could not be updated")
        static let updateErrorMessage = NSLocalizedString("Please try again later.", comment: "Prompt for the user to retry a failed action again later")
    }
}
