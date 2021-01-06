import UIKit

class JetpackScanViewController: UIViewController, JetpackScanView {
    private let site: JetpackSiteRef

    // IBOutlets
    @IBOutlet weak var tableView: UITableView!

    //
    var coordinator: JetpackScanCoordinator?

    // MARK: - Initializers
    init(site: JetpackSiteRef) {
        self.site = site
        super.init(nibName: nil, bundle: nil)
    }

    @objc convenience init?(blog: Blog) {
        precondition(blog.dotComID != nil)
        guard let siteRef = JetpackSiteRef(blog: blog) else {
            return nil
        }

        self.init(site: siteRef)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        coordinator = JetpackScanCoordinator(site: site, view: self)
        coordinator?.start()

        configureTableView()
    }

    // MARK: - JetpackScanView
    func render(_ scan: JetpackScan) {
        print("Hello")
        tableView.reloadData()
    }

    func showLoading() {
        print("Loading shown")
    }

    func showError() {
        print("oops")
    }

    // MARK: - Private: 
    private func configureTableView() {
        tableView.register(UINib(nibName: String(describing: JetpackScanStatusCell.self), bundle: nil),
                           forCellReuseIdentifier: Constants.statusCellIdentifier)

        tableView.register(UINib(nibName: String(describing: JetpackScanThreatCell.self), bundle: nil),
                           forCellReuseIdentifier: Constants.threatCellIdentifier)

        tableView.tableFooterView = UIView()
    }

    // MARK: - Private: Config
    private struct Constants {
        static let statusCellIdentifier = "StatusCell"
        static let threatCellIdentifier = "ThreatCell"
    }

    private struct Strings {

    }
}

// MARK: - Table View
extension JetpackScanViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = coordinator?.scan?.threats?.count ?? 0
        return count + 1
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
        guard let scan = coordinator?.scan else {
            return
        }

        tableView.beginUpdates()
        cell.configure(with: scan)
        tableView.endUpdates()
    }

    private func configureThreatCell(cell: JetpackScanThreatCell, threat: JetpackScanThreat) {
        cell.configure(with: threat)
    }

    private func threat(for indexPath: IndexPath) -> JetpackScanThreat? {
        guard let threats = coordinator?.scan?.threats else {
            return nil
        }

        let row = indexPath.row - 1

        return threats[row]
    }
}
