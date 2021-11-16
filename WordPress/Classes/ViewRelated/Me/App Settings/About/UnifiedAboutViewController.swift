import UIKit
import WordPressShared

/// Defines a single row in the unified about screen.
///
struct AboutItem {
    let title: String
    let subtitle: String?
    let cellStyle: AboutItemCellStyle
    let accessoryType: UITableViewCell.AccessoryType
    let hidesSeparator: Bool

    init(title: String, subtitle: String? = nil, cellStyle: AboutItemCellStyle = .default, accessoryType: UITableViewCell.AccessoryType = .disclosureIndicator, hidesSeparator: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.cellStyle = cellStyle
        self.accessoryType = accessoryType
        self.hidesSeparator = hidesSeparator
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

    var cellHeight: CGFloat {
        switch cellStyle {
        case .appLogos:
            return AutomatticAppLogosCell.Metrics.cellHeight
        default:
            return UITableView.automaticDimension
        }
    }

    var cellSelectionStyle: UITableViewCell.SelectionStyle {
        switch cellStyle {
        case .appLogos:
            return .none
        default:
            return .default
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

class UnifiedAboutViewController: UIViewController, OrientationLimited {
    enum ItemIdentifier {
        case rateUs
        case share
        case socialTwitter
        case socialFacebook
        case socialInstagram
        case legalAndMore
        case automatticFamily
        case appLogos
        case workWithUs
    }

    let sections: [[ItemIdentifier]] = [
        [
            .rateUs,
            .share,
            .socialTwitter
        ],
        [
            .legalAndMore
        ],
        [
            .automatticFamily,
            .appLogos
        ],
        [
            .workWithUs
        ]
    ]

    private static let appLogosIndexPath = IndexPath(row: 1, section: 2)

    let itemDetails: [ItemIdentifier: AboutItem] = [
        .rateUs: AboutItem(title: "Rate Us", accessoryType: .none),
        .share: AboutItem(title: "Share with Friends", accessoryType: .none),
        .socialTwitter: AboutItem(title: "Twitter", subtitle: "@WordPressiOS", cellStyle: .value1, accessoryType: .none),
        .legalAndMore: AboutItem(title: "Legal and More"),
        .automatticFamily: AboutItem(title: "Automattic Family", hidesSeparator: true),
        .appLogos: AboutItem(title: "", cellStyle: .appLogos),
        .workWithUs: AboutItem(title: "Work With Us", subtitle: "Join From Anywhere", cellStyle: .subtitle)
    ]

    var sharePresenter: ShareAppContentPresenter?

    // MARK: - Views

    let headerView: UIView = {
        // These customizations are temporarily here, but if this VC is moved into a framework we'll need to move them
        // into the main App.
        let appInfo = UnifiedAboutHeaderView.AppInfo(
            icon: UIImage(named: AppIcon.currentOrDefault.imageName) ?? UIImage(),
            name: (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ?? "",
            version: Bundle.main.detailedVersionNumber() ?? "")

        let fonts = UnifiedAboutHeaderView.Fonts(
            appName: WPStyleGuide.serifFontForTextStyle(.largeTitle, fontWeight: .semibold),
            appVersion: WPStyleGuide.tableviewTextFont())

        let headerView = UnifiedAboutHeaderView(appInfo: appInfo, fonts: fonts)

        // Setting the frame once is needed so that the table view header will show.
        // This seems to be a table view bug although I'm not entirely sure.
        headerView.frame.size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        return headerView
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        // Occasionally our hidden separator insets can cause the horizontal
        // scrollbar to appear on rotation
        tableView.showsHorizontalScrollIndicator = false

        tableView.tableHeaderView = headerView

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

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    // MARK: - View lifecycle

    init(sharePresenter: ShareAppContentPresenter? = nil) {
        self.sharePresenter = sharePresenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // When rotating (only on iPad), scroll so that the app logos cell is always visible
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.appLogosScrollDelay) {
            self.tableView.scrollToRow(at: UnifiedAboutViewController.appLogosIndexPath, at: .middle, animated: true)
        }
    }

    // MARK: - Navigation

    private func presentShareSheet(from view: UIView?) {
        sharePresenter?.present(for: .wordpress, in: self, source: .about, sourceView: view)
    }

    // MARK: - Constants

    enum Metrics {
        static let footerHeight: CGFloat = 58.0
        static let footerVerticalOffset: CGFloat = 20.0
    }

    enum Constants {
        static let appLogosScrollDelay: TimeInterval = 0.25
    }

    enum Images {
        static let automatticLogo = "automattic-logo"
    }
}

// MARK: - Table view data source

extension UnifiedAboutViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let identifier = section[indexPath.row]
        guard let item = itemDetails[identifier] else {
            return UITableViewCell()
        }

        let cell = item.makeCell()

        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.subtitle
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.accessoryType = item.accessoryType
        cell.selectionStyle = item.cellSelectionStyle

        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        let identifier = section[indexPath.row]
        let item = itemDetails[identifier]

        cell.separatorInset = (item?.hidesSeparator == true) ? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude) : tableView.separatorInset
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = sections[indexPath.section]
        let identifier = section[indexPath.row]
        let item = itemDetails[identifier]

        return item?.cellHeight ?? 0
    }
}

// MARK: - Table view delegate

extension UnifiedAboutViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        let identifier = section[indexPath.row]

        switch identifier {
        case .share:
            presentShareSheet(from: tableView.cellForRow(at: indexPath))
        default:
            break
        }

        tableView.deselectSelectedRowWithAnimation(true)
    }
}
