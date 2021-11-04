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

    // MARK: - Analytics

    private let tracker = UnifiedAboutTracker() { eventName, properties in
        // Part of this customization should happen in the App, so that we don't need to add analytics
        // dependencies into unified-about (and it remains tracker agnostic).
        //
        // We could decide to let the app create the tracker and pass it to the VC, or maybe
        // a simpler approach where the app can set a delegate / callback in the VC for tracking.
        //
        // I'm leaving these customizations here for now until we decide the concrete solution we want
        //
        let event = AnalyticsEvent(name: eventName, properties: properties)

        WPAnalytics.track(event)
    }

    // MARK: - Views

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.dataSource = self
        tableView.delegate = self

        return tableView
    }()

    private lazy var footerView: UIView = {
        let footerView = UIView()
        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.backgroundColor = .systemGroupedBackground

        let logo = UIImageView(image: UIImage(named: Images.automatticLogo))
        logo.translatesAutoresizingMaskIntoConstraints = false
        footerView.addSubview(logo)

        NSLayoutConstraint.activate([
            logo.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
            logo.centerYAnchor.constraint(equalTo: footerView.centerYAnchor)
        ])

        return footerView
    }()

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGroupedBackground

        view.addSubview(tableView)
        view.addSubview(footerView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: footerView.topAnchor),
            footerView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: Metrics.footerVerticalOffset),
            footerView.heightAnchor.constraint(equalToConstant: Metrics.footerHeight),
            footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        tableView.reloadData()
    }

    // MARK: - Constants

    enum Metrics {
        static let footerHeight: CGFloat = 58.0
        static let footerVerticalOffset: CGFloat = 20.0
    }

    enum Images {
        static let automatticLogo = "automattic-logo"
    }
}

// MARK: - Table view data source

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

// MARK: - Table view delegate

extension UnifiedAboutViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = Self.sections[indexPath.section]
        let row = section[indexPath.row]
        row.action?()
    }
}

class AutomatticAppLogosCell: UITableViewCell {
}
