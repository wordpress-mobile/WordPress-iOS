import UIKit
import WordPressFlux

class JetpackScanViewController: UIViewController, JetpackScanView {
    private let blog: Blog

    lazy var coordinator: JetpackScanCoordinator = {
        return JetpackScanCoordinator(blog: blog, view: self)
    }()

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

        self.title = NSLocalizedString("Scan", comment: "Title of the view")

        configureTableView()
        coordinator.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("History", comment: "Title of a navigation button that opens the scan history view"),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(showHistory))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        coordinator.viewWillDisappear()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        })
    }

    // MARK: - JetpackScanView
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
                                                   buttonText: NoResultsText.contactSupportButtonText)

        updateNoResults(model)
    }

    func showNoConnectionError() {
        let model =  NoResultsViewController.Model(title: NoResultsText.noConnection.title,
                                                   subtitle: NoResultsText.noConnection.subtitle,
                                                   buttonText: NoResultsText.tryAgainButtonText)

        updateNoResults(model)
    }

    func showScanStartError() {
        let model =  NoResultsViewController.Model(title: NoResultsText.scanStartError.title,
                                                   subtitle: NoResultsText.scanStartError.subtitle,
                                                   buttonText: NoResultsText.contactSupportButtonText)

        updateNoResults(model)

    }

    func presentAlert(_ alert: UIAlertController) {
        present(alert, animated: true, completion: nil)
    }

    func showFixThreatSuccess(for threat: JetpackScanThreat) {
        self.navigationController?.popToViewController(self, animated: true)

        let model = JetpackScanThreatViewModel(threat: threat)
        let notice = Notice(title: model.fixSuccessTitle)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    func showIgnoreThreatSuccess(for threat: JetpackScanThreat) {
        self.navigationController?.popToViewController(self, animated: true)

        let model = JetpackScanThreatViewModel(threat: threat)
        let notice = Notice(title: model.ignoreSuccessTitle)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    func showFixThreatError(for threat: JetpackScanThreat) {
        let model = JetpackScanThreatViewModel(threat: threat)
        let notice = Notice(title: model.fixErrorTitle)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    func showIgnoreThreatError(for threat: JetpackScanThreat) {
        let model = JetpackScanThreatViewModel(threat: threat)
        let notice = Notice(title: model.ignoreErrorTitle)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    // MARK: - Actions
    @objc func showHistory() {
        let viewController = JetpackScanHistoryViewController(blog: blog)
        navigationController?.pushViewController(viewController, animated: true)
    }

    // MARK: - Private: 
    private func configureTableView() {
        tableView.register(JetpackScanStatusCell.defaultNib, forCellReuseIdentifier: Constants.statusCellIdentifier)
        tableView.register(JetpackScanThreatCell.defaultNib, forCellReuseIdentifier: Constants.threatCellIdentifier)

        tableView.tableFooterView = UIView()

        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(userRefresh), for: .valueChanged)
    }

    @objc func userRefresh() {
        coordinator.refreshData()
    }

    // MARK: - Private: Config
    private struct Constants {
        static let statusCellIdentifier = "StatusCell"
        static let threatCellIdentifier = "ThreatCell"

        /// The number of header rows, used to get the threat rows
        static let tableHeaderCountOffset = 1
    }
}

extension JetpackScanViewController: JetpackScanThreatDetailsViewControllerDelegate {

    func willFixThreat(_ threat: JetpackScanThreat, controller: JetpackScanThreatDetailsViewController) {
        coordinator.fixThreat(threat: threat)
    }

    func willIgnoreThreat(_ threat: JetpackScanThreat, controller: JetpackScanThreatDetailsViewController) {
        coordinator.ignoreThreat(threat: threat)
    }

}

// MARK: - Table View
extension JetpackScanViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = coordinator.threats?.count ?? 0
        return count + Constants.tableHeaderCountOffset
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        if indexPath.row == 0 {
            let statusCell = tableView.dequeueReusableCell(withIdentifier: Constants.statusCellIdentifier) as? JetpackScanStatusCell ?? JetpackScanStatusCell(style: .default, reuseIdentifier: Constants.statusCellIdentifier)

            configureStatusCell(cell: statusCell)

            cell = statusCell
        } else {
            let threatCell = tableView.dequeueReusableCell(withIdentifier: Constants.threatCellIdentifier) as? JetpackScanThreatCell ?? JetpackScanThreatCell(style: .default, reuseIdentifier: Constants.threatCellIdentifier)

            if let threat = threat(for: indexPath) {
                configureThreatCell(cell: threatCell, threat: threat)
            }

            cell = threatCell
        }

        return cell
    }

    private func configureStatusCell(cell: JetpackScanStatusCell) {
        guard let model = JetpackScanStatusViewModel(coordinator: coordinator) else {
            // TODO: handle error
            return
        }

        cell.configure(with: model)
    }

    private func configureThreatCell(cell: JetpackScanThreatCell, threat: JetpackScanThreat) {
        let model = JetpackScanThreatViewModel(threat: threat)
        cell.configure(with: model)
    }

    private func threat(for indexPath: IndexPath) -> JetpackScanThreat? {
        let row = indexPath.row - Constants.tableHeaderCountOffset

        guard row >= 0, let threats = coordinator.threats else {
            return nil
        }

        return threats[row]
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let threat = threat(for: indexPath) else {
            return
        }

        let threatDetailsVC = JetpackScanThreatDetailsViewController(blog: blog, threat: threat)
        threatDetailsVC.delegate = self
        self.navigationController?.pushViewController(threatDetailsVC, animated: true)
    }
}

// MARK: - Loading / Errors
extension JetpackScanViewController: NoResultsViewControllerDelegate {
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
            static let title = NSLocalizedString("Loading Scan...", comment: "Text displayed while loading the scan section for a site")
        }

        struct scanStartError {
            static let title = NSLocalizedString("Something went wrong", comment: "Title for the error view when the scan start has failed")
            static let subtitle = NSLocalizedString("Jetpack Scan couldn't complete a scan of your site. Please check to see if your site is down – if it's not, try again. If it is, or if Jetpack Scan is still having problems, contact our support team.", comment: "Error message shown when the scan start has failed.")
        }

        struct error {
            static let title = NSLocalizedString("Oops", comment: "Title for the view when there's an error loading scan status")
            static let subtitle = NSLocalizedString("There was an error loading the scan status", comment: "Text displayed when there is a failure loading the status")
        }

        struct noConnection {
            static let title = NSLocalizedString("No connection", comment: "Title for the error view when there's no connection")
            static let subtitle = NSLocalizedString("An active internet connection is required to view Jetpack Scan", comment: "Error message shown when trying to view the scan status and there is no internet connection.")
        }

        static let tryAgainButtonText = NSLocalizedString("Try again", comment: "Button label for trying to retrieve the scan status again")
        static let contactSupportButtonText = NSLocalizedString("Contact support", comment: "Button label for contacting support")
    }
}
