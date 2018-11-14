import UIKit
import WordPressComStatsiOS

@objc protocol SiteStatsInsightsDelegate {
    @objc optional func displayWebViewWithURL(_ url: URL)
    @objc optional func showCreatePost()
    @objc optional func showShareForPost(postID: NSNumber, fromView: UIView)
    @objc optional func latestPostSummaryLoaded(_ summaryData: StatsLatestPostSummary?)
}

class SiteStatsInsightsTableViewController: UITableViewController {

    // MARK: - Properties

    var latestPostSummary: StatsLatestPostSummary?

    private lazy var mainContext: NSManagedObjectContext = {
        return ContextManager.sharedInstance().mainContext
    }()

    private lazy var blogService: BlogService = {
        return BlogService(managedObjectContext: mainContext)
    }()

    private lazy var postService: PostService = {
        return PostService(managedObjectContext: mainContext)
    }()

    private var viewModel: SiteStatsInsightsViewModel {
        return SiteStatsInsightsViewModel(insightsDelegate: self)
    }

    private lazy var tableHandler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        WPStyleGuide.Stats.configureTable(tableView)
        refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        ImmuTable.registerRows([LatestPostSummaryRow.self], tableView: tableView)
        viewModel.fetchStats()
    }

}

// MARK: - Private Extension

private extension SiteStatsInsightsTableViewController {

    // MARK: - Table Model

    func tableViewModel() -> ImmuTable {
        let latestPostSummaryRow = LatestPostSummaryRow(summaryData: latestPostSummary, siteStatsInsightsDelegate: self)

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: [
                    latestPostSummaryRow
                ])
            ])
    }

    func refreshModel() {
        tableHandler.viewModel = tableViewModel()
        refreshControl?.endRefreshing()
    }

    @objc func refreshData() {
        refreshControl?.beginRefreshing()
        viewModel.fetchStats()
    }

}

// MARK: - SiteStatsInsightsDelegate Methods

extension SiteStatsInsightsTableViewController: SiteStatsInsightsDelegate {

    func latestPostSummaryLoaded(_ summaryData: StatsLatestPostSummary?) {
        latestPostSummary = summaryData
        refreshModel()
    }

    func displayWebViewWithURL(_ url: URL) {
        let webViewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url)
        let navController = UINavigationController.init(rootViewController: webViewController)
        present(navController, animated: true, completion: nil)
    }

    func showCreatePost() {
        WPTabBarController.sharedInstance().showPostTab { [weak self] in
            self?.viewModel.fetchStats()
        }
    }

    func showShareForPost(postID: NSNumber, fromView: UIView) {

        guard let blogId = SiteStatsInformation.sharedInstance.siteID,
        let blog = blogService.blog(byBlogId: blogId) else {
            DDLogInfo("Failed to get blog with id \(String(describing: SiteStatsInformation.sharedInstance.siteID))")
            return
        }

        postService.getPostWithID(postID, for: blog, success: { apost in
            guard let post = apost as? Post else {
                DDLogInfo("Failed to get post with id \(postID)")
                return
            }

            let shareController = PostSharingController()
            shareController.sharePost(post, fromView: fromView, inViewController: self)
        }, failure: { error in
            DDLogInfo("Error getting post with id \(postID): \(error.localizedDescription)")
        })
    }

}
