import UIKit

/// Displays search results from a reader site search.
///
class ReaderSiteSearchViewController: UITableViewController {

    // MARK: - Properties

    lazy var tableHandler: WPTableViewHandler = {
        let tableHandler = WPTableViewHandler(tableView: self.tableView)
        return tableHandler
    }()

    var feeds: [ReaderFeed] = []

    var searchTerm: String? = nil {
        didSet {
            performSearch(for: searchTerm)
        }
    }

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
    }

    // MARK: - Actions

    private func performSearch(for term: String?) {
        guard let term = term,
            !term.isEmpty else {
                return
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = ReaderSiteSearchService(managedObjectContext: context)
        service.performSearch(withQuery: term,
                              page: 0,
                              success: { [weak self] (feeds, _, _) in
            self?.feeds = feeds
            self?.tableView.reloadData()
            }, failure: { _ in
        })
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
        cell.detailTextLabel?.text = feed.url.absoluteString
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
