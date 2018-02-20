import UIKit

class SignupEpilogueTableViewController: NUXTableViewController {

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        let headerNib = UINib(nibName: "LoginEpilogueSectionHeader", bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: "SectionHeader")

        let displayNameNib = UINib(nibName: "SignupEpilogueDisplayNameCell", bundle: nil)
        tableView.register(displayNameNib, forCellReuseIdentifier: "DisplayNameCell")

        WPStyleGuide.configureColors(for: view, andTableView: tableView)

        // remove empty cells
        tableView.tableFooterView = UIView()
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // display name & username section
        if section == 1 {
            return 2
        }

        // user info, password sections
        return 1
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var sectionTitle = ""
        if section == 0 {
            sectionTitle = NSLocalizedString("New Account", comment: "Header for user info, shown after account created.").localizedUppercase
        }

        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SectionHeader") as? LoginEpilogueSectionHeader else {
            fatalError("Failed to get a section header cell")
        }
        cell.titleLabel?.text = sectionTitle

        return cell
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "DisplayNameCell") as? SignupEpilogueDisplayNameCell else {
                    fatalError("Failed to get a display name cell")
                }
                return cell
            }
        }

        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableViewAutomaticDimension
    }

}
