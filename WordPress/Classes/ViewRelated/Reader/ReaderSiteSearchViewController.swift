import UIKit

/// Displays search results from a reader site search.
///
class ReaderSiteSearchViewController: UITableViewController, UIViewControllerRestoration {

    // MARK: - Properties
    // MARK: Table / Sync Handlers

    fileprivate lazy var tableHandler: WPTableViewHandler = {
        let tableHandler = WPTableViewHandler(tableView: self.tableView)
        return tableHandler
    }()

    fileprivate lazy var syncHelper: WPContentSyncHelper = {
        let syncHelper = WPContentSyncHelper()
        syncHelper.delegate = self
        return syncHelper
    }()

    // MARK: Data

    fileprivate var feeds: [ReaderFeed] = [] {
        didSet {
            reloadData()
        }
    }
    fileprivate var totalFeedCount: Int = 0

    var searchQuery: String? = nil {
        didSet {
            feeds = []
            totalFeedCount = 0

            syncHelper.syncContentWithUserInteraction(false)
        }
    }

    // MARK: Views

    private let statusViewController = NoResultsViewController.controller()
    fileprivate let headerView = ReaderSiteSearchHeaderView()
    fileprivate let footerView = ReaderSiteSearchFooterView()

    // MARK: - State restoration

    private static let restorationClassIdentifier = "ReaderSiteSearchRestorationIdentifier"

    static func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        return ReaderSiteSearchViewController()
    }

    // MARK: - View lifecycle

    init() {
        super.init(style: .plain)

        restorationIdentifier = ReaderSiteSearchViewController.restorationClassIdentifier
        restorationClass = ReaderSiteSearchViewController.self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        WPStyleGuide.configureColors(for: self.view, andTableView: tableView)

        tableView.register(WPBlogTableViewCell.self, forCellReuseIdentifier: WPBlogTableViewCell.reuseIdentifier())

        configureTableHeaderView()
        configureTableFooterView()

        view.backgroundColor = .clear
    }

    private func configureTableHeaderView() {
        tableView.tableHeaderView = headerView
        headerView.isHidden = true
    }

    private func configureTableFooterView() {
        footerView.showSpinner(false)
        footerView.delegate = self

        tableView.tableFooterView = footerView
        footerView.isHidden = true
    }

    // MARK: - Actions

    private func performSearch(with query: String?,
                               page: Int,
                               success: ((_ hasMore: Bool) -> Void)?,
                               failure: ((_ error: NSError) -> Void)?) {
        guard let query = query,
            !query.isEmpty else {
                return
        }

        if page == 0 {
            showLoadingView()
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = ReaderSiteSearchService(managedObjectContext: context)
        service.performSearch(with: query,
                              page: page,
                              success: { [weak self] (feeds, hasMore, totalFeeds) in
                                self?.feeds.append(contentsOf: feeds)
                                self?.totalFeedCount = totalFeeds
                                self?.reloadData(hasMoreResults: hasMore)
                                success?(hasMore)
            }, failure: { [weak self] error in
                self?.handleFailedSearch()

                if let error = error as NSError? {
                    failure?(error)
                }
        })
    }

    private func reloadData(hasMoreResults: Bool = false) {
        tableView.reloadData()

        let noFeeds = feeds.count == 0

        footerView.isHidden = noFeeds
        headerView.isHidden = noFeeds

        hideStatusView()
        if noFeeds {
            showNoResultsView()
        } else {
            footerView.showSpinner(hasMoreResults)
        }
    }

    private func handleFailedSearch() {
        if feeds.count == 0 {
            showLoadingFailedView()
        }

        syncHelper.hasMoreContent = false
        footerView.showSpinner(false)
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feeds.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WPBlogTableViewCell.reuseIdentifier(), for: indexPath)

        let feed = feeds[indexPath.row]
        configureCell(cell, forFeed: feed)

        return cell
    }

    private func configureCell(_ cell: UITableViewCell, forFeed feed: ReaderFeed) {
        WPStyleGuide.configureTableViewBlogCell(cell)

        cell.textLabel?.text = feed.title
        cell.detailTextLabel?.text =  feed.urlForDisplay

        cell.accessoryType = .disclosureIndicator

        if let blavatarURL = feed.blavatarURL {
            cell.imageView?.downloadSiteIcon(at: blavatarURL.absoluteString,
                                             placeholderImage: UIImage.siteIconPlaceholderImage)
        } else {
            cell.imageView?.image = UIImage.siteIconPlaceholderImage
        }
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let isLastSection = indexPath.section == tableView.numberOfSections - 1
        let isLastRow = indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1
        if isLastSection && isLastRow {
            if syncHelper.hasMoreContent {
                syncHelper.syncMoreContent()
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let feed = feeds[indexPath.row]

        guard let streamViewController = readerStreamViewController(for: feed) else {
            return
        }

        navigationController?.pushViewController(streamViewController, animated: true)
    }

    private func readerStreamViewController(for feed: ReaderFeed) -> ReaderStreamViewController? {
        if let feedID = feed.feedID, let feedIDValue = Int(feedID) {
            return ReaderStreamViewController.controllerWithSiteID(feedIDValue as NSNumber,
                                                                   isFeed: true)
        } else if let blogID = feed.blogID, let blogIDValue = Int(blogID) {
            return ReaderStreamViewController.controllerWithSiteID(blogIDValue as NSNumber,
                                                                   isFeed: false)
        }

        return nil
    }
}

// MARK: - Status View

private extension ReaderSiteSearchViewController {

    func showNoResultsView() {
        let messageText = String(format: StatusText.messageFormat, searchQuery ?? "")
        configureAndDisplayStatus(title: StatusText.noResultsTitle, subtitle: messageText)
    }

    func showLoadingView() {
        configureAndDisplayStatus(title: StatusText.loadingTitle, accessoryView: loadingAccessoryView())
    }

    func showLoadingFailedView() {
        configureAndDisplayStatus(title: StatusText.loadingFailedTitle, subtitle: StatusText.loadingFailedMessage)
    }

    func configureAndDisplayStatus(title: String,
                                   subtitle: String? = nil,
                                   accessoryView: UIView? = nil) {

        statusViewController.configure(title: title, subtitle: subtitle, image: "wp-illustration-empty-results", accessoryView: accessoryView)
        showStatusView()
    }

    func showStatusView() {
        hideStatusView()
        addChildViewController(statusViewController)
        tableView.addSubview(withFadeAnimation: statusViewController.view)
        statusViewController.view.frame = tableView.frame

        // The tableView doesn't start at y = 0, making the No Results View vertically off-center.
        // So adjust the NRV accordingly.
        statusViewController.view.frame.origin.y -= tableView.frame.origin.y

        statusViewController.didMove(toParentViewController: self)
    }

    func hideStatusView() {
        statusViewController.removeFromView()
    }

    func loadingAccessoryView() -> UIView {
        let boxView = WPAnimatedBox()
        boxView.animate(afterDelay: 0.3)
        return boxView
    }

    struct StatusText {
        static let loadingTitle = NSLocalizedString("Fetching sites...", comment: "A brief prompt when the user is searching for sites in the Reader.")
        static let loadingFailedTitle = NSLocalizedString("Problem loading sites", comment: "Error message title informing the user that a search for sites in the Reader could not be loaded.")
        static let loadingFailedMessage = NSLocalizedString("Sorry. Your search results could not be loaded.", comment: "A short error message leting the user know the requested search could not be performed.")
        static let noResultsTitle = NSLocalizedString("No sites found", comment: "A message title")
        static let messageFormat = NSLocalizedString("No sites found matching %@ in your language.", comment: "Message shown when the reader finds no sites for the specified search phrase. The %@ is a placeholder for the search phrase.")
    }

}

// MARK: - WPContentSyncHelperDelegate

extension ReaderSiteSearchViewController: WPContentSyncHelperDelegate {
    func syncHelper(_ syncHelper: WPContentSyncHelper, syncMoreWithSuccess success: ((Bool) -> Void)?, failure: ((NSError) -> Void)?) {
        let nextPage = Int(round(Float(feeds.count)/Float(ReaderSiteSearchService.pageSize)))

        performSearch(with: searchQuery,
                      page: nextPage,
                      success: success,
                      failure: failure)
    }

    func syncHelper(_ syncHelper: WPContentSyncHelper, syncContentWithUserInteraction userInteraction: Bool, success: ((Bool) -> Void)?, failure: ((NSError) -> Void)?) {
        performSearch(with: searchQuery,
                      page: 0,
                      success: success,
                      failure: failure)
    }
}

// MARK: - ReaderSiteSearchFooterViewDelegate

extension ReaderSiteSearchViewController: ReaderSiteSearchFooterViewDelegate {
    func readerSiteSearchFooterViewDidChangeFrame(_ footerView: ReaderSiteSearchFooterView) {
        // Refresh the footer view's frame
        tableView.tableFooterView = footerView
    }
}

extension ReaderFeed {
    /// Strips the protocol and query from the URL.
    ///
    var urlForDisplay: String {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let host = components.host else {
            return url.absoluteString
        }

        let path = components.path
        if path.isEmpty && path != "/" {
            return host + path
        } else {
            return host
        }
    }
}

// MARK: - Header / Footer views

private let collapsedHeaderFooterHeight: CGFloat = 9.0
private let headerFooterDividerHeight: CGFloat = 1.0

class ReaderSiteSearchHeaderView: UIView {
    private let divider = UIView()

    init() {
        super.init(frame: .zero)

        backgroundColor = .clear
        frame.size.height = collapsedHeaderFooterHeight

        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = WPStyleGuide.postCardBorderColor()
        addSubview(divider)

        NSLayoutConstraint.activate([
            divider.bottomAnchor.constraint(equalTo: bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: headerFooterDividerHeight),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Simple protocol that reports when the footer view has changed its frame.
/// The delegate can then use this to re-set and resize the associated
/// tableview's footer view property.
///
protocol ReaderSiteSearchFooterViewDelegate: class {
    func readerSiteSearchFooterViewDidChangeFrame(_ footerView: ReaderSiteSearchFooterView)
}

class ReaderSiteSearchFooterView: UIView {
    private let divider = UIView()
    private let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    weak var delegate: ReaderSiteSearchFooterViewDelegate? = nil

    private static let expandedHeight: CGFloat = 44.0

    init() {
        super.init(frame: .zero)

        backgroundColor = .clear
        frame.size.height = ReaderSiteSearchFooterView.expandedHeight

        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = WPStyleGuide.postCardBorderColor()
        addSubview(divider)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            divider.topAnchor.constraint(equalTo: topAnchor),
            divider.heightAnchor.constraint(equalToConstant: headerFooterDividerHeight),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showSpinner(_ show: Bool) {
        if show {
            activityIndicator.startAnimating()
            frame.size.height = ReaderSiteSearchFooterView.expandedHeight
            delegate?.readerSiteSearchFooterViewDidChangeFrame(self)
        } else {
            activityIndicator.stopAnimating()
            frame.size.height = collapsedHeaderFooterHeight
            delegate?.readerSiteSearchFooterViewDidChangeFrame(self)
        }
    }
}
