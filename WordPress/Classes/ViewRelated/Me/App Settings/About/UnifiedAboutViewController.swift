import UIKit
import WordPressShared


class UnifiedAboutViewController: UIViewController, OrientationLimited {
    let configuration: AboutScreenConfiguration

    private var sections: [AboutScreenSection] {
        configuration.sections
    }

    private var appLogosIndexPath: IndexPath? {
        for (sectionIndex, row) in sections.enumerated() {
            if let rowIndex = row.firstIndex(where: { $0.cellStyle == .appLogos }) {
                return IndexPath(row: rowIndex, section: sectionIndex)
            }
        }

        return nil
    }

    // MARK: - Views


    // MARK: - Views

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        // Occasionally our hidden separator insets can cause the horizontal
        // scrollbar to appear on rotation
        tableView.showsHorizontalScrollIndicator = false

        tableView.tableHeaderView = headerView
        tableView.tableFooterView = footerView

        tableView.dataSource = self
        tableView.delegate = self

        return tableView
    }()

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

    private lazy var footerView: UIView = {
        let footerView = UIView()
        footerView.backgroundColor = .systemGroupedBackground

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.addSubview(containerView)

        let logo = UIImageView(image: UIImage(named: Images.automatticLogo))
        logo.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(logo)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: footerView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: footerView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: footerView.topAnchor, constant: Metrics.footerVerticalOffset),
            containerView.bottomAnchor.constraint(equalTo: footerView.bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: Metrics.footerHeight),
            logo.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            logo.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])

        footerView.frame.size = footerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        return footerView
    }()

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    // MARK: - View lifecycle

    static func controller(configuration: AboutScreenConfiguration) -> UIViewController {
        let controller = UnifiedAboutViewController(configuration: configuration)
        return UINavigationController(rootViewController: controller)
    }

    init(configuration: AboutScreenConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(true, animated: false)

        view.backgroundColor = .systemGroupedBackground

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        tableView.reloadData()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if let indexPath = appLogosIndexPath {
            // When rotating (only on iPad), scroll so that the app logos cell is always visible
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.appLogosScrollDelay) {
                self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            }
        }
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
        let item = section[indexPath.row]

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
        let item = section[indexPath.row]

        cell.separatorInset = item.hidesSeparator ? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude) : tableView.separatorInset
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = sections[indexPath.section]
        let item = section[indexPath.row]

        return item.cellHeight
    }
}

// MARK: - Table view delegate

extension UnifiedAboutViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        let item = section[indexPath.row]

        let context = AboutItemActionContext(viewController: self, sourceView: tableView.cellForRow(at: indexPath))

        if let customAction = item.action {
            let defaultAction = customAction(context)

            switch defaultAction {
            case .showSubmenu(let configuration):
                let viewController = SubmenuViewController(configuration: configuration)
                viewController.title = item.title

                navigationController?.pushViewController(viewController, animated: true)
            default:
                break
            }
        }

        tableView.deselectSelectedRowWithAnimation(true)
    }
}

// MARK: AboutItem Extensions

private extension AboutItem {
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
}

/// Generic VC for custom submenus.
///
class SubmenuViewController: UITableViewController {
    let configuration: AboutSubmenuConfiguration

    var sections: [AboutScreenSection] {
        configuration.sections
    }

    init(configuration: AboutSubmenuConfiguration) {
        self.configuration = configuration
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "" //item.title

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    // MARK: - Actions

    @objc private func doneTapped() {
        let context = AboutItemActionContext(viewController: self)
        configuration.dismissBlock(context)
    }

    private static let cellIdentifier = "AboutLinkListViewController.Cell"

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        let item = section[indexPath.row]

        let context = AboutItemActionContext(viewController: self, sourceView: tableView.cellForRow(at: indexPath))

        if let customAction = item.action {
            let defaultAction = customAction(context)

            switch defaultAction {
            case .showSubmenu(let configuration):
                let viewController = SubmenuViewController(configuration: configuration)
                viewController.title = item.title

                navigationController?.pushViewController(viewController, animated: true)
            default:
                break
            }
        }

        tableView.deselectSelectedRowWithAnimation(true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let item = section[indexPath.row]

        let cell = item.makeCell()

        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.subtitle
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.accessoryType = item.accessoryType
        cell.selectionStyle = item.cellSelectionStyle

        return cell
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        let item = section[indexPath.row]

        cell.separatorInset = item.hidesSeparator ? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude) : tableView.separatorInset
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = sections[indexPath.section]
        let item = section[indexPath.row]

        return item.cellHeight
    }
}
