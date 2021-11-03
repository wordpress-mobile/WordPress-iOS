import UIKit

/// Defines a single row in the unified about screen.
///
struct AboutItem {
    let title: String
    let subtitle: String?
    let cellStyle: AboutItemCellStyle
    let action: (() -> Void)?

    init(title: String, subtitle: String? = nil, cellStyle: AboutItemCellStyle = .default, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.cellStyle = cellStyle
        self.action = action
    }

    func makeCell() -> UITableViewCell {
        switch cellStyle {
        case .default:
            return UITableViewCell(style: .default, reuseIdentifier: cellStyle.rawValue)
        case .value1:
            return UITableViewCell(style: .value1, reuseIdentifier: cellStyle.rawValue)
        case .subtitle:
            return UITableViewCell(style: .subtitle, reuseIdentifier: cellStyle.rawValue)
        case .appLogos:
            return AutomatticAppLogosCell()
        }
    }

    enum AboutItemCellStyle: String {
        // Displays only a title
        case `default`
        // Displays a title on the leading side and a secondary value on the trailing side
        case value1
        // Displays a title with a smaller subtitle below
        case subtitle
        // Displays the custom app logos cell
        case appLogos
    }
}

class UnifiedAboutViewController: UIViewController {
    static let sections: [[AboutItem]] = [
        [
            AboutItem(title: "Rate Us"),
            AboutItem(title: "Share with Friends"),
            AboutItem(title: "Twitter", cellStyle: .value1)
        ],
        [
            AboutItem(title: "Legal and More")
        ],
        [
            AboutItem(title: "Automattic Family"),
            AboutItem(title: "", cellStyle: .appLogos)
        ],
        [
            AboutItem(title: "Work With Us", subtitle: "Join From Anywhere", cellStyle: .subtitle)
        ]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        tableView.dataSource = self
        tableView.delegate = self

        tableView.reloadData()
    }
}

extension UnifiedAboutViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Self.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Self.sections[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Self.sections[indexPath.section]
        let row = section[indexPath.row]

        let cell = row.makeCell()

        cell.textLabel?.text = row.title
        cell.detailTextLabel?.text = row.subtitle
        cell.accessoryType = .disclosureIndicator

        return cell
    }
}

extension UnifiedAboutViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = Self.sections[indexPath.section]
        let row = section[indexPath.row]
        row.action?()
    }
}

class AutomatticAppLogosCell: UITableViewCell {
}
