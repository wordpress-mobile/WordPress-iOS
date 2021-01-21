import UIKit

class JetpackScanHistoryViewController: UIViewController, JetpackScanHistoryView {
    private let blog: Blog

    lazy var coordinator: JetpackScanHistoryCoordinator = {
        return JetpackScanHistoryCoordinator(blog: blog, view: self)
    }()


    @IBOutlet weak var filterTabBar: FilterTabBar!

    // Table View
    @IBOutlet weak var tableView: UITableView!
    let refreshControl = UIRefreshControl()

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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        })
    }

    // MARK: - JetpackScanView
    func render() {
        refreshControl.endRefreshing()
        tableView.reloadData()
    }

    func showLoading() {

    }

    func showError() {

    }

    func presentAlert(_ alert: UIAlertController) {
        present(alert, animated: true, completion: nil)
    }

    // MARK: - Actions
    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        let selectedIndex = filterTabBar.selectedIndex
        guard let filter = JetpackScanHistoryCoordinator.Filter(rawValue: selectedIndex) else {
            return
        }

        coordinator.changeFilter(filter)
    }

    // MARK: - Private:
    private func configureFilterTabBar() {
        WPStyleGuide.configureFilterTabBar(filterTabBar)
        filterTabBar.superview?.backgroundColor = .filterBarBackground

        filterTabBar.tabSizingStyle = .equalWidths
        filterTabBar.items = coordinator.filterItems
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }

    private func configureTableView() {
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
        static let threatCellIdentifier = "ThreatHistoryCell"
    }
}

// MARK: - Table View
extension JetpackScanHistoryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return coordinator.threats?.count ?? 0
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


    private func configureThreatCell(cell: JetpackScanThreatCell, threat: JetpackScanThreat) {
        let model = JetpackScanThreatViewModel(threat: threat)
        cell.configure(with: model)
    }

    private func threat(for indexPath: IndexPath) -> JetpackScanThreat? {
        guard let threats = coordinator.threats else {
            return nil
        }

        return threats[indexPath.row]
    }
}
