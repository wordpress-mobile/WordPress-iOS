import UIKit

/// A cell that displays topics the user might like
///
class ReaderTopicsCardCell: ReaderTopicsTableCardCell {
    private let cellIdentifier = "TopicCell"

    override func configure(_ data: [ReaderAbstractTopic]) {
        super.configure(data)

        headerTitle = Constants.title
    }

    override func setupTableView() {
        super.setupTableView()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    }

    override func cell(forRowAt indexPath: IndexPath, tableView: UITableView, topic: ReaderAbstractTopic?) -> UITableViewCell {
        guard let tagTopic = topic as? ReaderTagTopic else {
            return UITableViewCell()
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath)
        cell.textLabel?.text = tagTopic.title
        cell.accessoryType = .disclosureIndicator
        cell.separatorInset = UIEdgeInsets.zero
        cell.backgroundColor = .clear

        return cell
    }

    private enum Constants {
        static let title = NSLocalizedString("You might like", comment: "A suggestion of topics the user might like")
    }
}
