import UIKit

class JetpackScanViewController: UIViewController, JetpackScanView {
    private let blog: Blog

    lazy var coordinator: JetpackScanCoordinator = {
        return JetpackScanCoordinator(blog: blog, view: self)
    }()

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

        configureTableView()
        coordinator.viewDidLoad()
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
    func render(_ scan: JetpackScan) {
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
        guard let threats = coordinator.threats else {
            return nil
        }

        let row = indexPath.row - Constants.tableHeaderCountOffset

        return threats[row]
    }
}
