import UIKit

/// A cell that displays topics the user might like
///
class ReaderSitesCardCell: ReaderTopicsTableCardCell {
    private let cellIdentifier = "SitesTopicCell"

    override func configure(_ data: [ReaderAbstractTopic]) {
        super.configure(data)

        headerTitle = Constants.title
        headerContentInsets = UIEdgeInsets(top: 10, left: 15, bottom: -5, right: 0)
    }

    override func setupTableView() {
        super.setupTableView()

        let cell = UINib(nibName: "ReaderRecommendedSiteCardCell", bundle: Bundle.main)
        tableView.register(cell, forCellReuseIdentifier: cellIdentifier)
    }

    override func cell(forRowAt indexPath: IndexPath, tableView: UITableView, topic: ReaderAbstractTopic?) -> UITableViewCell {
        guard
            let siteTopic = topic as? ReaderSiteTopic,
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath) as? ReaderRecommendedSiteCardCell
            else {
            return UITableViewCell()
        }

        cell.configure(siteTopic)
        return cell
    }

    private enum Constants {
        static let title = NSLocalizedString("Sites to follow", comment: "A suggestion of topics the user might ")
    }
}
