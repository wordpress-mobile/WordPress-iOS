import UIKit

/// A cell that displays topics the user might like
///
class ReaderSitesCardCell: ReaderTopicsTableCardCell {
    private let cellIdentifier = "SitesTopicCell"

    override func configure(_ data: [ReaderAbstractTopic]) {
        super.configure(data)

        headerTitle = Constants.title
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
        cell.delegate = self
        return cell
    }

    func didToggleFollowing(_ topic: ReaderAbstractTopic, with success: Bool) {
        guard let row = data.firstIndex(of: topic) else {
            return
        }

        tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
    }

    private enum Constants {
        static let title = NSLocalizedString("Sites to follow", comment: "A suggestion of topics the user might ")
    }
}

protocol ReaderSitesCardCellDelegate: ReaderTopicsTableCardCellDelegate {
    func handleFollowActionForTopic(_ topic: ReaderAbstractTopic, for cell: ReaderSitesCardCell)
}

extension ReaderSitesCardCell: ReaderRecommendedSitesCardCellDelegate {
    func handleFollowActionForCell(_ cell: ReaderRecommendedSiteCardCell) {
        guard
            let indexPath = self.tableView.indexPath(for: cell),
            let topic = data[indexPath.row] as? ReaderSiteTopic
        else {
            return
        }

        (delegate as? ReaderSitesCardCellDelegate)?.handleFollowActionForTopic(topic, for: self)

        // Track Follow Action
        var properties = [String: Any]()
        properties[WPAppAnalyticsKeyFollowAction] = !topic.following
        properties[WPAppAnalyticsKeyBlogID] = topic.siteID

        WPAnalytics.trackReader(.readerSuggestedSiteToggleFollow, properties: properties)
    }
}
