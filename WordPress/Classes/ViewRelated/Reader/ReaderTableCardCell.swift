import UIKit

/// A cell that contains a table that displays a list of ReaderAbstractTopic's
///
class ReaderTopicsTableCardCell: UITableViewCell {
    private let containerView = UIView()

    let tableView: UITableView = ReaderTopicsTableView()

    private(set) var data: [ReaderAbstractTopic] = [] {
        didSet {
            guard oldValue != data else {
                return
            }

            tableView.reloadData()
        }
    }

    /// Constraints to be activated in compact horizontal size class
    private var compactConstraints: [NSLayoutConstraint] = []

    /// Constraints to be activated in regular horizontal size class
    private var regularConstraints: [NSLayoutConstraint] = []

    weak var delegate: ReaderTopicsTableCardCellDelegate?

    // Subclasses should configure these properties
    var headerTitle: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupTableView()
        applyStyles()

        // Since iOS 14, the contentView is in the top of the view hierarchy.
        // This conflicts with the tableView interaction, so we disable it.
        contentView.isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        refreshHorizontalConstraints()
    }

    func configure(_ data: [ReaderAbstractTopic]) {
        self.data = data
    }

    func setupTableView() {
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToSafeArea(containerView, insets: Constants.containerInsets)
        containerView.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        let tableViewMargin = 16.0
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: tableViewMargin),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -tableViewMargin)
        ])

        // Constraints for regular horizontal size class
        regularConstraints = [
            tableView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor, constant: tableViewMargin),
            tableView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor, constant: -tableViewMargin)
        ]

        // Constraints for compact horizontal size class
        compactConstraints = [
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: tableViewMargin),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -tableViewMargin)
        ]

        tableView.isScrollEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func applyStyles() {
        containerView.backgroundColor = .systemBackground
        tableView.backgroundColor = .secondarySystemBackground
        tableView.layer.cornerRadius = 10.0
        tableView.separatorColor = .clear

        backgroundColor = .clear
        contentView.backgroundColor = .clear

        refreshHorizontalConstraints()
    }

    func cell(forRowAt indexPath: IndexPath, tableView: UITableView, topic: ReaderAbstractTopic?) -> UITableViewCell {
        return UITableViewCell()
    }

    // Activate and deactivate constraints based on horizontal size class
    private func refreshHorizontalConstraints() {
        let isCompact = (traitCollection.horizontalSizeClass == .compact)

        compactConstraints.forEach { $0.isActive = isCompact }
        regularConstraints.forEach { $0.isActive = !isCompact }
    }

    private enum Constants {
        static let containerInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        static let headerInsets = UIEdgeInsets(top: 8, left: 16, bottom: 0, right: 0)
        static let tableFooterHeight: CGFloat = 8.0
    }
}

extension ReaderTopicsTableCardCell: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableCell = cell(forRowAt: indexPath, tableView: tableView, topic: data[indexPath.row])

        tableCell.backgroundColor = .clear
        tableCell.contentView.backgroundColor = .clear

        return tableCell
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return Constants.tableFooterHeight
    }
}

extension ReaderTopicsTableCardCell: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = headerTitle else {
            return nil
        }
        let header = UIView()
        let headerTitle = UILabel()
        headerTitle.text = title
        header.addSubview(headerTitle)
        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        header.pinSubviewToAllEdges(headerTitle, insets: Constants.headerInsets)
        headerTitle.font = WPStyleGuide.fontForTextStyle(.footnote)
        headerTitle.textColor = .secondaryLabel
        return header
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let topic = data[indexPath.row]
        delegate?.didSelect(topic: topic)
        tableView.deselectSelectedRowWithAnimation(true)
    }
}

private class ReaderTopicsTableView: UITableView {
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

protocol ReaderTopicsTableCardCellDelegate: AnyObject {
    func didSelect(topic: ReaderAbstractTopic)
}
