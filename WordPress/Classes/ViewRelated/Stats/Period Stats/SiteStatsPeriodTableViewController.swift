import UIKit

class SiteStatsPeriodTableViewController: UITableViewController {

    // MARK: - Properties


    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = WPStyleGuide.greyLighten30()
        setupSimpleTotalsCell()
        // refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SimpleTotalsCell.defaultReuseID, for: indexPath) as! SimpleTotalsCell

        cell.configure(dataRows: [])

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func setupSimpleTotalsCell() {
        let nib = UINib(nibName: SimpleTotalsCell.defaultNibName, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: SimpleTotalsCell.defaultReuseID)
    }

}
