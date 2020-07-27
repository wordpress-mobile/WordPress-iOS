import UIKit

protocol ReaderTopicsCellDelegate: class {
    func didSelect(topic: ReaderTagTopic)
}

/// A cell that displays topics the user might like
///
class ReaderSuggestedTopicsCell: UITableViewCell {
    private let containerView = UIView()

    private let tableView = TopicsTableView()

    private var topics: [ReaderTagTopic] = [] {
        didSet {
            guard oldValue != topics else {
                return
            }

            tableView.reloadData()
        }
    }

    private let cellIdentifier = "TopicCell"

    /// Constraints to be activated in compact horizontal size class
    private var compactConstraints: [NSLayoutConstraint] = []

    /// Constraints to be activated in regular horizontal size class
    private var regularConstraints: [NSLayoutConstraint] = []

    weak var delegate: ReaderTopicsCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupTableView()
        applyStyles()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        refreshHorizontalConstraints()
    }

    func configure(_ topics: [ReaderTagTopic]) {
        self.topics = topics
    }

    private func setupTableView() {
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(containerView, insets: Constants.containerInsets)
        containerView.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: containerView.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        // Constraints for regular horizontal size class
        regularConstraints = [
            tableView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor)
        ]

        // Constraints for compact horizontal size class
        compactConstraints = [
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ]

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.isScrollEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func applyStyles() {
        containerView.backgroundColor = .listForeground

        tableView.backgroundColor = .none
        tableView.separatorColor = .placeholderElement

        backgroundColor = .none

        refreshHorizontalConstraints()
    }

    // Activate and deactivate constraints based on horizontal size class
    private func refreshHorizontalConstraints() {
        let isCompact = (traitCollection.horizontalSizeClass == .compact)

        compactConstraints.forEach { $0.isActive = isCompact }
        regularConstraints.forEach { $0.isActive = !isCompact }
    }

    private enum Constants {
        static let containerInsets = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        static let title = NSLocalizedString("You might like", comment: "A suggestion of topics the user might ")
    }
}

extension ReaderSuggestedTopicsCell: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topics.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath)
        cell.textLabel?.text = topics[indexPath.row].title
        cell.accessoryType = .disclosureIndicator
        cell.separatorInset = UIEdgeInsets.zero
        cell.backgroundColor = .none
        return cell
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
}

extension ReaderSuggestedTopicsCell: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        let headerTitle = UILabel()
        headerTitle.text = Constants.title
        header.addSubview(headerTitle)
        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        header.pinSubviewToAllEdges(headerTitle, insets: UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 0))
        headerTitle.font = WPStyleGuide.serifFontForTextStyle(.title2)
        return header
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let topic = topics[indexPath.row]
        delegate?.didSelect(topic: topic)
        tableView.deselectSelectedRowWithAnimation(true)
    }
}

private class TopicsTableView: UITableView {
    override var intrinsicContentSize: CGSize {
        self.layoutIfNeeded()
        return self.contentSize
    }

    override var contentSize: CGSize {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }
}
