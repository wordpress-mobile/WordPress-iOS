import UIKit

class JetpackScanViewController: UIViewController, JetpackScanView {
    private let site: JetpackSiteRef

    // IBOutlets
    @IBOutlet weak var tableView: UITableView!

    //
    var coordinator: JetpackScanCoordinator?

    let meow = JetpackStatusViewController()

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

        let nib = UINib(nibName: String(describing: JetpackScanThreatCell.self), bundle: nil)

        tableView.register(nib, forCellReuseIdentifier: "Meow")
        tableView.reloadData()
    }

    // MARK: - JetpackScanView
    func render(_ scan: JetpackScan) {
        print(scan)
    }

    func showLoading() {
        print("Loading shown")
    }

    func showError() {
        print("oops")
    }

    // MARK: - Private: Config
    private struct Constants {
    }

    private struct Strings {

    }
}

// MARK: - Table View
extension JetpackScanViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Meow") as? JetpackScanThreatCell

        if cell == nil {
            cell = JetpackScanThreatCell(style: .default, reuseIdentifier: "Meow")
        }

        cell?.titleLabel.text = "Hello"
        return cell!
    }


    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return meow.view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return meow.view.frame.height
    }
}
