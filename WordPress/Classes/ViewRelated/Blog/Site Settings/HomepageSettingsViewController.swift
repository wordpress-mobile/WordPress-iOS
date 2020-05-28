import UIKit
import WordPressFlux
import WordPressShared

@objc open class HomepageSettingsViewController: UITableViewController {

    enum UpdateState {
        case homepageType
        case selectedHomepage
        case selectedPostsPage

        /// Compares each property from `blog` and produces an update state based on which changed
        init?(blog: Blog, homepageType: HomepageType, postsPageID: Int?, homepagePageID: Int?) {
            if blog.homepageType != homepageType {
                self = .homepageType
            } else if blog.homepagePostsPageID != postsPageID {
                self = .selectedPostsPage
            } else if blog.homepagePageID != homepagePageID {
                self = .selectedHomepage
            } else {
                return nil
            }
        }
    }

    /// Are we currently updating the homepage type?
    fileprivate var updateState: UpdateState? = nil

    fileprivate var postService: PostService!

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

    // MARK: - Model

    fileprivate func reloadViewModel() {
        handler.viewModel = tableViewModel
    }

    fileprivate var tableViewModel: ImmuTable {
        guard let homepageType = blog.homepageType else {
            return ImmuTable(sections: [])
        }

        let homepageRows: [ImmuTableRow]
        if case .homepageType = updateState {
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
                self?.setHomepageType(.posts, postsPageID: self?.blog.homepagePostsPageID, homePageID: self?.blog.homepagePageID)
            }),
            CheckmarkRow(title: HomepageType.page.title, checked: homepageType == .page, action: { [weak self] _ in
                self?.setHomepageType(.page, postsPageID: self?.blog.homepagePostsPageID, homePageID: self?.blog.homepagePageID)
            })
        ]
    }

    var selectedPagesRows: [ImmuTableRow] {
        var homepageTitle = ""
        var postsPageTitle = ""

        if let homepageID = blog.homepagePageID,
            let homepage = postService.findPost(withID: NSNumber(value: homepageID), in: blog) {
            homepageTitle = homepage.titleForDisplay()
        }

        if let postsPageID = blog.homepagePostsPageID,
            let postsPage = postService.findPost(withID: NSNumber(value: postsPageID), in: blog) {
            postsPageTitle = postsPage.titleForDisplay()
        }

        let homepageRow: ImmuTableRow
        if case .selectedHomepage = updateState {
            homepageRow = ActivityIndicatorRow(title: Strings.homepage, animating: true, action: nil)
        } else {
            homepageRow = NavigationItemRow(title: Strings.homepage, detail: homepageTitle, action: { _ in
                self.pushPageSelection(selectedPostID: self.blog?.homepagePageID, hiddenPostID: self.blog.homepagePostsPageID) { [weak self] selected in
                    if let postID = selected.postID?.intValue {
                        self?.setHomepageType(.page, postsPageID: self?.blog.homepagePostsPageID, homePageID: postID)
                    }
                }
            })
        }

        let postsPageRow: ImmuTableRow
        if case .selectedPostsPage = updateState {
            postsPageRow = ActivityIndicatorRow(title: Strings.postsPage, animating: true, action: nil)
        } else {
            postsPageRow = NavigationItemRow(title: Strings.postsPage, detail: postsPageTitle, action: { _ in
                self.pushPageSelection(selectedPostID: self.blog?.homepagePostsPageID, hiddenPostID: self.blog?.homepagePageID) { [weak self] selected in
                    if let postID = selected.postID?.intValue {
                        self?.setHomepageType(.page, postsPageID: postID, homePageID: self?.blog.homepagePageID)
                    }
                }
            })
        }

        return [homepageRow, postsPageRow]
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateDeselectionInteractively()
    }

    fileprivate func pushPageSelection(selectedPostID: Int?, hiddenPostID: Int?, _ completion: @escaping (Page) -> Void) {
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
                                                      hiddenPosts: hiddenPosts) { (post) in
            if let page = post as? Page {
                completion(page)
            }
            self.navigationController?.popViewController(animated: true)
        }
        viewController.title = NSLocalizedString("Choose Posts Page", comment: "Title for selecting a new home page")
        navigationController?.pushViewController(viewController, animated: true)
    }

    fileprivate func endUpdating() {
        updateState = nil
        reloadViewModel()
    }

    fileprivate func setHomepageType(_ type: HomepageType,
                                     postsPageID: Int?,
                                     homePageID: Int?) {

        guard updateState == nil else {
                return
        }

        updateState = UpdateState(blog: blog, homepageType: type, postsPageID: postsPageID, homepagePageID: homePageID)

        /// Will be `nil` if there are no changes to `blog`
        guard updateState != nil else {
            return
        }

        let service = HomepageSettingsService(blog: blog, context: blog.managedObjectContext!)
        service?.setHomepageType(type,
                                 withPostsPageID: postsPageID,
                                 homePageID: homePageID,
                                 success: { [weak self] in
            self?.endUpdating()
        }, failure: { [weak self] error in
            self?.endUpdating()

            let notice = Notice(title: Strings.updateErrorTitle, message: Strings.updateErrorMessage, feedbackType: .error)
            ActionDispatcher.global.dispatch(NoticeAction.post(notice))
        })

        reloadViewModel()
    }

    // MARK: - Private Properties
    fileprivate var blog: Blog!

    fileprivate enum Strings {
        static let title = NSLocalizedString("Homepage Settings", comment: "Title for the Homepage Settings screen")
        static let footerText = NSLocalizedString("Choose from a homepage that displays your latest posts (classic blog) or a fixed / static page.", comment: "Explanatory text for Homepage Settings homepage type selection.")
        static let homepage = NSLocalizedString("Homepage", comment: "Title for setting which shows the current page assigned as a site's homepage")
        static let postsPage = NSLocalizedString("Posts Page", comment: "Title for setting which shows the current page assigned as a site's posts page")
        static let choosePagesHeaderText = NSLocalizedString("Choose Pages", comment: "Title for settings section which allows user to select their home page and posts page")
        static let updateErrorTitle = NSLocalizedString("Unable to update homepage settings", comment: "Error informing the user that their homepage settings could not be updated")
        static let updateErrorMessage = NSLocalizedString("Please try again later.", comment: "Prompt for the user to retry a failed action again later")
    }
}
