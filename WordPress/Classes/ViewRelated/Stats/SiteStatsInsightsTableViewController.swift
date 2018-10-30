import UIKit

class SiteStatsInsightsTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = WPStyleGuide.greyLighten30()
        setUpLatestPostSummaryCell()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.latestPostSummary, for: indexPath) as! LatestPostSummaryCell
        cell.configure()
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

}

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
