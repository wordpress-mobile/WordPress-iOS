import UIKit

class JetpackScanHistoryViewController: UIViewController {
    private let blog: Blog

    lazy var coordinator: JetpackScanHistoryCoordinator = {
        return JetpackScanHistoryCoordinator(blog: blog, view: self)
    }()

    @IBOutlet weak var filterTabBar: FilterTabBar!

    // Table View
    @IBOutlet weak var tableView: UITableView!
    let refreshControl = UIRefreshControl()

    // Loading / Errors
    private var noResultsViewController: NoResultsViewController?

    // MARK: - Initializers
    @objc init(blog: Blog) {
        self.blog = blog
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("Scan History", comment: "Title of the view")

        configureTableView()
        configureFilterTabBar()
        coordinator.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        WPAnalytics.track(.jetpackScanHistoryAccessed)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        })
    }

    // MARK: - Actions
    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        let selectedIndex = filterTabBar.selectedIndex
        guard let filter = JetpackScanHistoryCoordinator.Filter(rawValue: selectedIndex) else {
            return
        }

        coordinator.changeFilter(filter)

        WPAnalytics.track(.jetpackScanHistoryFilter, properties: ["filter": filter.eventProperty])
    }

    // MARK: - Private: Config
    private func configureFilterTabBar() {
        WPStyleGuide.configureFilterTabBar(filterTabBar)
        filterTabBar.superview?.backgroundColor = .filterBarBackground

        filterTabBar.tabSizingStyle = .equalWidths
        filterTabBar.items = coordinator.filterItems
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }

    private func configureTableView() {
        tableView.register(JetpackScanThreatCell.defaultNib, forCellReuseIdentifier: Constants.threatCellIdentifier)

        tableView.register(ActivityListSectionHeaderView.defaultNib,
                           forHeaderFooterViewReuseIdentifier: ActivityListSectionHeaderView.identifier)

        tableView.tableFooterView = UIView()

        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(userRefresh), for: .valueChanged)
    }

    @objc func userRefresh() {
        coordinator.refreshData()
    }

    // MARK: - Private: Config
    private struct Constants {
        static let threatCellIdentifier = "ThreatHistoryCell"
    }
}

extension JetpackScanHistoryViewController: JetpackScanHistoryView {
    func render() {
        updateNoResults(nil)

        refreshControl.endRefreshing()
        tableView.reloadData()
    }

    func showLoading() {
        let model = NoResultsViewController.Model(title: NoResultsText.loading.title,
                                                  accessoryView: NoResultsViewController.loadingAccessoryView())
        updateNoResults(model)
    }

    func showGenericError() {
        let model =  NoResultsViewController.Model(title: NoResultsText.error.title,
                                                   subtitle: NoResultsText.error.subtitle,
                                                   buttonText: NoResultsText.error.buttonText)

        updateNoResults(model)
    }

    func showNoConnectionError() {
        let model =  NoResultsViewController.Model(title: NoResultsText.noConnection.title,
                                                   subtitle: NoResultsText.noConnection.subtitle,
                                                   buttonText: NoResultsText.tryAgainButtonText)

        updateNoResults(model)
    }

    func showNoHistory() {
        let model = NoResultsViewController.Model(title: NoResultsText.noHistory.title)
        updateNoResults(model)
    }

    func showNoIgnoredThreats() {
        let model =  NoResultsViewController.Model(title: NoResultsText.noIgnoredThreats.title,
                                                   subtitle: NoResultsText.noIgnoredThreats.subtitle)

        updateNoResults(model)
    }

    func showNoFixedThreats() {
        let model =  NoResultsViewController.Model(title: NoResultsText.noFixedThreats.title,
                                                   subtitle: NoResultsText.noFixedThreats.subtitle)

        updateNoResults(model)
    }
}
// MARK: - Table View
extension JetpackScanHistoryViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return coordinator.sections?.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let historySection = coordinator.sections?[section] else {
            return 0
        }

        return historySection.threats.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell

        let threatCell = tableView.dequeueReusableCell(withIdentifier: Constants.threatCellIdentifier) as? JetpackScanThreatCell ?? JetpackScanThreatCell(style: .default, reuseIdentifier: Constants.threatCellIdentifier)

        if let threat = threat(for: indexPath) {
            configureThreatCell(cell: threatCell, threat: threat)
        }

        cell = threatCell

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let historySection = coordinator.sections?[section],
            let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: ActivityListSectionHeaderView.identifier) as? ActivityListSectionHeaderView else {
            return UIView(frame: .zero)
        }

        cell.titleLabel.text = historySection.title

        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return ActivityListSectionHeaderView.height
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let threat = threat(for: indexPath) else {
            return
        }

        let threatDetailsVC = JetpackScanThreatDetailsViewController(blog: blog, threat: threat)
        self.navigationController?.pushViewController(threatDetailsVC, animated: true)

        WPAnalytics.track(.jetpackScanThreatListItemTapped, properties: ["threat_signature": threat.signature, "section": "history"])

    }

    private func configureThreatCell(cell: JetpackScanThreatCell, threat: JetpackScanThreat) {
        let model = JetpackScanThreatViewModel(threat: threat)
        cell.configure(with: model)
    }

    private func threat(for indexPath: IndexPath) -> JetpackScanThreat? {
        guard let section = coordinator.sections?[indexPath.section] else {
            return nil
        }

        return section.threats[indexPath.row]
    }
}

// MARK: - Loading / Errors
extension JetpackScanHistoryViewController: NoResultsViewControllerDelegate {
    func updateNoResults(_ viewModel: NoResultsViewController.Model?) {
        if let noResultsViewModel = viewModel {
            showNoResults(noResultsViewModel)
        } else {
            noResultsViewController?.view.isHidden = true
        }

        tableView.reloadData()
    }

    private func showNoResults(_ viewModel: NoResultsViewController.Model) {
        if noResultsViewController == nil {
            noResultsViewController = NoResultsViewController.controller()
            noResultsViewController?.delegate = self

            guard let noResultsViewController = noResultsViewController else {
                return
            }

            if noResultsViewController.view.superview != tableView {
                tableView.addSubview(withFadeAnimation: noResultsViewController.view)
            }

            addChild(noResultsViewController)

            noResultsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        }

        noResultsViewController?.bindViewModel(viewModel)
        noResultsViewController?.didMove(toParent: self)
        tableView.pinSubviewToSafeArea(noResultsViewController!.view)
        noResultsViewController?.view.isHidden = false
    }

    func actionButtonPressed() {
        coordinator.noResultsButtonPressed()
    }

    private struct NoResultsText {
        struct loading {
            static let title = NSLocalizedString("Loading Scan History...", comment: "Text displayed while loading the scan history for a site")
        }

        struct noHistory {
            static let title = NSLocalizedString("No history yet", comment: "Title for the view when there aren't any history items to display")
        }

        struct error {
            static let title = NSLocalizedString("Oops", comment: "Title for the view when there's an error loading Activity Log")
            static let subtitle = NSLocalizedString("There was an error loading the scan history", comment: "Text displayed when there is a failure loading the history feed")
            static let buttonText = NSLocalizedString("Contact support", comment: "Button label for contacting support")
        }

        struct noConnection {
            static let title = NSLocalizedString("No connection", comment: "Title for the error view when there's no connection")
            static let subtitle = NSLocalizedString("An active internet connection is required to view the history", comment: "Error message shown when trying to view the Scan History feature and there is no internet connection.")
        }

        struct noFixedThreats {
            static let title = NSLocalizedString("No fixed threats", comment: "Title for the view when there aren't any fixed threats to display")
            static let subtitle = NSLocalizedString("So far, there are no fixed threats on your site.", comment: "Text display in the view when there aren't any Activities Types to display in the Activity Log Types picker")
        }

        struct noIgnoredThreats {
            static let title = NSLocalizedString("No ignored threats", comment: "Title for the view when there aren't any ignored threats to display")
            static let subtitle = NSLocalizedString("So far, there are no ignored threats on your site.", comment: "Text display in the view when there aren't any Activities Types to display in the Activity Log Types picker")
        }

        static let tryAgainButtonText = NSLocalizedString("Try again", comment: "Button label for trying to retrieve the history again")
    }
}

extension ActivityListSectionHeaderView: NibLoadable { }
