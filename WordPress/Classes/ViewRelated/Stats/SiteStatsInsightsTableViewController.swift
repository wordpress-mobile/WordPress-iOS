import UIKit
import WordPressComStatsiOS

class SiteStatsInsightsTableViewController: UITableViewController {

    // MARK: - Properties

    var statsService: WPStatsService?
    var latestPostSummary: StatsLatestPostSummary?
    var loadingProgressDelegate: StatsLoadingProgressDelegate?

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = WPStyleGuide.greyLighten30()
        setUpLatestPostSummaryCell()
        refreshControl?.addTarget(self, action: #selector(fetchStats), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchStats()
    }

    // MARK: - Table Methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if latestPostSummary != nil {
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.latestPostSummary, for: indexPath) as! LatestPostSummaryCell
            cell.configure(withData: latestPostSummary)
            return cell
        }

        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

}

// MARK: - Data Fetching

private extension SiteStatsInsightsTableViewController {

    @objc func fetchStats() {

        loadingProgressDelegate?.didBeginLoadingStats(viewController: self)

        statsService?.retrieveInsightsStats(allTimeStatsCompletionHandler: { (allTimeStats, error) in

        }, insightsCompletionHandler: { (mostPopularStats, error) in

        }, todaySummaryCompletionHandler: { (todaySummary, error) in

        }, latestPostSummaryCompletionHandler: { (latestPostSummary, error) in
            if error != nil {
                DDLogDebug("Error fetching latest post summary: \(String(describing: error?.localizedDescription))")
                self.latestPostSummary = nil
            } else {
                self.latestPostSummary = latestPostSummary
                self.tableView.reloadData()
            }
        }, commentsAuthorCompletionHandler: { (commentsAuthors, error) in

        }, commentsPostsCompletionHandler: { (commentsPosts, error) in

        }, tagsCategoriesCompletionHandler: { (tagsCategories, error) in

        }, followersDotComCompletionHandler: { (followersDotCom, error) in

        }, followersEmailCompletionHandler: { (followersEmail, error) in

        }, publicizeCompletionHandler: { (publicize, error) in

        }, streakCompletionHandler: { (statsStreak, error) in

        }, progressBlock: { (numberOfFinishedOperations, totalNumberOfOperations) in
                let percentage = Float(numberOfFinishedOperations) / Float(totalNumberOfOperations)
                self.loadingProgressDelegate?.statsLoadingProgress(viewController: self, percentage: percentage)
        }, andOverallCompletionHandler: {
            self.loadingProgressDelegate?.didEndLoadingStats(viewController: self)
            self.refreshControl?.endRefreshing()
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
