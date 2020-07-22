import UIKit

class ReaderTopicsCell: UITableViewCell {
    let tableView = OwnTableView()

    var interests: [ReaderInterest] = []

    private let cellIdentifier = "MyCell"

    var compactConstraints: [NSLayoutConstraint] = []
    var regularConstraints: [NSLayoutConstraint] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let containerView = UIView()
        addSubview(containerView)
        containerView.backgroundColor = .listForeground
        containerView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(containerView, insets: UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0))
        containerView.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: containerView.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        regularConstraints = [
            tableView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor)
        ]
        compactConstraints = [
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ]
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.isScrollEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
        tableView.backgroundColor = .none
        tableView.separatorColor = .placeholderElement
        backgroundColor = .none
        refreshHorizontalConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        refreshHorizontalConstraints()
    }

    private func refreshHorizontalConstraints() {
        let isCompact = (traitCollection.horizontalSizeClass == .compact)

        compactConstraints.forEach { $0.isActive = isCompact }
        regularConstraints.forEach { $0.isActive = !isCompact }
    }
}

extension ReaderTopicsCell: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return interests.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath)
        cell.textLabel?.text = interests[indexPath.row].title
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

extension ReaderTopicsCell: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        let headerTitle = UILabel()
        headerTitle.text = "You might like"
        header.addSubview(headerTitle)
        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        header.pinSubviewToAllEdges(headerTitle, insets: UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 0))
        headerTitle.font = WPStyleGuide.serifFontForTextStyle(.title2)
        return header
    }
}

class OwnTableView: UITableView {
    override var intrinsicContentSize: CGSize {
        self.layoutIfNeeded()
        return self.contentSize
    }

    override var contentSize: CGSize {
        didSet{
            self.invalidateIntrinsicContentSize()
        }
    }
}
