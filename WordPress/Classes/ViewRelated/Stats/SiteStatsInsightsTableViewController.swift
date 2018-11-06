import UIKit
import WordPressComStatsiOS

@objc protocol SiteStatsInsightsDelegate {
    @objc optional func displayWebViewWithURL(_ url: URL)
    @objc optional func showCreatePost()
}

class SiteStatsInsightsTableViewController: UITableViewController {

    // MARK: - Properties

    var statsService: WPStatsService?
    var latestPostSummary: StatsLatestPostSummary?
    private var finishedLoading = false

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        WPStyleGuide.Stats.configureTable(tableView)
        setUpLatestPostSummaryCell()
        refreshControl?.addTarget(self, action: #selector(fetchStats), for: .valueChanged)

        fetchStats()
    }

    // MARK: - Table Methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard finishedLoading == true else {
            return 0
        }

        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.latestPostSummary, for: indexPath) as! LatestPostSummaryCell
        cell.configure(withData: latestPostSummary, andDelegate: self)
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

}

// MARK: - Data Fetching

private extension SiteStatsInsightsTableViewController {

    @objc func fetchStats() {

        finishedLoading = false

        statsService?.retrieveInsightsStats(allTimeStatsCompletionHandler: { (allTimeStats, error) in

        }, insightsCompletionHandler: { (mostPopularStats, error) in

        }, todaySummaryCompletionHandler: { (todaySummary, error) in

        }, latestPostSummaryCompletionHandler: { (latestPostSummary, error) in
            if error != nil {
                DDLogDebug("Error fetching latest post summary: \(String(describing: error?.localizedDescription))")
                self.latestPostSummary = nil
            } else {
                self.latestPostSummary = latestPostSummary
            }
            self.tableView.reloadData()
        }, commentsAuthorCompletionHandler: { (commentsAuthors, error) in

        }, commentsPostsCompletionHandler: { (commentsPosts, error) in

        }, tagsCategoriesCompletionHandler: { (tagsCategories, error) in

        }, followersDotComCompletionHandler: { (followersDotCom, error) in

        }, followersEmailCompletionHandler: { (followersEmail, error) in

        }, publicizeCompletionHandler: { (publicize, error) in

        }, streakCompletionHandler: { (statsStreak, error) in

        }, progressBlock: { (numberOfFinishedOperations, totalNumberOfOperations) in

        }, andOverallCompletionHandler: {
            self.refreshControl?.endRefreshing()
            self.finishedLoading = true
        })

    }
}


// MARK: - Cell Support

private extension SiteStatsInsightsTableViewController {

    func setUpLatestPostSummaryCell() {
        let nib = UINib(nibName: NibNames.latestPostSummary, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: ReuseIdentifiers.latestPostSummary)
    }

    struct NibNames {
        static let latestPostSummary = "LatestPostSummaryCell"
    }

    struct ReuseIdentifiers {
        static let latestPostSummary = "latestPostSummaryCell"
    }
}

// MARK: - SiteStatsInsightsDelegate Methods

extension SiteStatsInsightsTableViewController: SiteStatsInsightsDelegate {

    func displayWebViewWithURL(_ url: URL) {
        let webViewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url)
        navigationController?.pushViewController(webViewController, animated: true)
    }

    func showCreatePost() {
        WPTabBarController.sharedInstance().showPostTab { [weak self] in
            self?.fetchStats()
        }
    }

}
