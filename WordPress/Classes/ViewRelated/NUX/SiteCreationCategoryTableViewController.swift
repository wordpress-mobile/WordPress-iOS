import UIKit
import WordPressAuthenticator


class SiteCreationCategoryTableViewController: NUXTableViewController {

    // MARK: - Properties

    fileprivate var tableHandler: ImmuTableViewHandler!

    // MARK: - View

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupTable()
        setupNavBar()
    }

    func setupTable() {
        ImmuTable.registerRows([InstructionRow.self, SiteTypeRow.self], tableView: tableView)
        tableHandler = ImmuTableViewHandler(takeOver: self)
        tableHandler.viewModel = tableViewModel()
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        // remove empty cells
        tableView.tableFooterView = UIView()
    }

    func setupNavBar() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                           target: self,
                                           action: #selector(handleCancelButtonTapped))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.title = NSLocalizedString("Create New Site", comment: "Create New Site title.")
    }

    // MARK: - Cancel Button Action

    @objc func handleCancelButtonTapped(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table Model

    private func tableViewModel() -> ImmuTable {
        let step = NSLocalizedString("Step 1 of 4", comment: "Title for first step in the site creation process.").localizedUppercase
        let instr1 = NSLocalizedString("What kind of site do you need?", comment: "Site type question.")
        let instr2 = NSLocalizedString("Choose an option below:", comment: "Choose site type prompt.")
        let instructionRow = InstructionRow(step: step, instr1: instr1, instr2: instr2, action: nil)

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: [
                    instructionRow,
                    createRowFor(.blog),
                    createRowFor(.website),
                    createRowFor(.portfolio)
                ])
            ])
    }

    private func createRowFor(_ siteType: SiteType) -> SiteTypeRow {

        var typeDescription: String
        var typeTitle: String

        switch siteType {
        case .blog:
            typeDescription = NSLocalizedString("To share your ideas, stories and photographs with your followers.", comment: "Site type description.")
            typeTitle = NSLocalizedString("Start with a Blog", comment: "Start with site type.")
        case .website:
            typeDescription = NSLocalizedString("To promote your business or brand, and connect with your audience.", comment: "Site type description.")
            typeTitle = NSLocalizedString("Start with a Website", comment: "Start with site type.")
        case .portfolio:
            typeDescription = NSLocalizedString("To present your creative projects in a visual showcase.", comment: "Site type description.")
            typeTitle = NSLocalizedString("Start with a Portfolio", comment: "Start with site type.")
        }

        let typeImage = UIImage(named: "site-creation-\(siteType)")

        return SiteTypeRow(siteType: siteType, startWith: typeTitle, typeDescr: typeDescription, typeImage: typeImage, action: siteTypeRowSelected())
    }


    // MARK: - Row Handler

    private func siteTypeRowSelected() -> ImmuTableAction {
        return { [unowned self] row in
            self.performSegue(withIdentifier: "showThemeSelection", sender: row)
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        tableView.deselectSelectedRowWithAnimation(true)

        guard let themeVC = segue.destination as? SiteCreationThemeSelectionViewController else {
            return
        }

        guard let tableRow = sender as? SiteTypeRow else {
            return
        }

        themeVC.siteType = tableRow.siteType

        let backButton = UIBarButtonItem()
        backButton.title = NSLocalizedString("Back", comment: "Back button title.")
        navigationItem.backBarButtonItem = backButton
    }

    // MARK: - Misc

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
