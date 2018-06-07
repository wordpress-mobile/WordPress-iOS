import UIKit

/// Displays search results from a reader site search.
///
class ReaderSiteSearchViewController: UITableViewController {

    // MARK: - Properties

    lazy var tableHandler: WPTableViewHandler = {
        let tableHandler = WPTableViewHandler(tableView: self.tableView)
        return tableHandler
    }()

    var feeds: [ReaderFeed] = [] {
        didSet {
            reloadData()
        }
    }

    var searchTerm: String? = nil {
        didSet {
            feeds = []

            performSearch(for: searchTerm)
        }
    }

    let statusView: WPNoResultsView = {
        let view = WPNoResultsView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - View lifecycle

    init() {
        super.init(style: .plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        WPStyleGuide.configureColors(for: self.view, andTableView: tableView)

        tableView.register(WPBlogTableViewCell.self, forCellReuseIdentifier: WPBlogTableViewCell.reuseIdentifier())
        tableView.tableFooterView = UIView()

        view.backgroundColor = .clear
    }

    // MARK: - Actions

    private func performSearch(for term: String?) {
        guard let term = term,
            !term.isEmpty else {
                return
        }

        showLoadingView()

        let context = ContextManager.sharedInstance().mainContext
        let service = ReaderSiteSearchService(managedObjectContext: context)
        service.performSearch(withQuery: term,
                              page: 0,
                              success: { [weak self] (feeds, _, _) in
            self?.feeds = feeds
            self?.reloadData()
            }, failure: { [weak self] _ in
                self?.showLoadingFailedView()
        })
    }

    private func reloadData() {
        tableView.reloadData()

        if feeds.count == 0 {
            showNoResultsView()
        } else {
            hideStatusView()
        }
    }

    // MARK: - Status View

    private func showNoResultsView() {
        statusView.titleText = NSLocalizedString("No sites found", comment: "A message title")

        let localizedMessageText = NSLocalizedString("No sites found matching %@ in your language.", comment: "Message shown when the reader finds no sites for the specified search phrase. The %@ is a placeholder for the search phrase.")
        statusView.messageText = NSString(format: localizedMessageText as NSString, searchTerm ?? "") as String

        statusView.accessoryView = nil
        statusView.buttonTitle = nil

        showStatusView()
    }

    private func showLoadingView() {
        statusView.titleText = NSLocalizedString("Fetching sites...", comment: "A brief prompt when the user is searching for sites in the Reader.")
        statusView.messageText = ""
        statusView.buttonTitle = nil

        let boxView = WPAnimatedBox()
        statusView.accessoryView = boxView
        showStatusView()
        boxView.animate(afterDelay: 0.3)
    }

    private func showLoadingFailedView() {
        statusView.titleText = NSLocalizedString("Problem loading sites", comment: "Error message title informing the user that a search for sites in the Reader could not be loaded.")
        statusView.messageText = NSLocalizedString("Sorry. Your search results could not be loaded.", comment: "A short error message leting the user know the requested search could not be performed.")
        showStatusView()
    }

    private func showStatusView() {
        if !statusView.isDescendant(of: tableView) {
            tableView.addSubview(withFadeAnimation: statusView)
            tableView.pinSubviewAtCenter(statusView)
        }
    }

    private func hideStatusView() {
        statusView.removeFromSuperview()
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

extension ReaderFeed {
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
