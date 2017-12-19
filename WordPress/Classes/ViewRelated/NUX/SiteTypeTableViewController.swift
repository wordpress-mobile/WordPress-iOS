import UIKit

class SiteTypeTableViewController: UITableViewController, LoginWithLogoAndHelpViewController {

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
        _ = addHelpButtonToNavController()
        navigationItem.title = NSLocalizedString("Create New Site", comment: "Create New Site title.")
    }

    // MARK: - Cancel Button Action

    @objc func handleCancelButtonTapped(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table Model

    private func tableViewModel() -> ImmuTable {

        let step = NSLocalizedString("STEP 1 OF 4", comment: "Step for view.")
        let instr1 = NSLocalizedString("What kind of site do you need?", comment: "Site type question.")
        let instr2 = NSLocalizedString("Choose an option below:", comment: "Choose site type prompt.")
        let instructionRow = InstructionRow(step: step, instr1: instr1, instr2: instr2, action: nil)

        let blog = NSLocalizedString("Start with a Blog", comment: "Start with site type.")
        let blogDescr = NSLocalizedString("To share your ideas, stories and photographs with your followers.", comment: "Site type description.")
        let blogImage = UIImage(named: "site-creation-blog")
        let blogRow = SiteTypeRow(startWith: blog, typeDescr: blogDescr, typeImage: blogImage, action: siteTypeRowSelected("Blog"))

        let website = NSLocalizedString("Start with a Website", comment: "Start with site type.")
        let websiteDescr = NSLocalizedString("To promote your business or brand, and connect with your audience.", comment: "Site type description.")
        let websiteImage = UIImage(named: "site-creation-website")
        let websiteRow = SiteTypeRow(startWith: website, typeDescr: websiteDescr, typeImage: websiteImage, action: siteTypeRowSelected("Website"))

        let portfolio = NSLocalizedString("Start with a Portfolio", comment: "Start with site type.")
        let portfolioDescr = NSLocalizedString("To present your creative projects in a visual showcase.", comment: "Site type description.")
        let portfolioImage = UIImage(named: "site-creation-portfolio")
        let portfolioRow = SiteTypeRow(startWith: portfolio, typeDescr: portfolioDescr, typeImage: portfolioImage, action: siteTypeRowSelected("Portfolio"))

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: [
                    instructionRow,
                    blogRow,
                    websiteRow,
                    portfolioRow
                ])
            ])
    }

    // MARK: - Row Handler

    func siteTypeRowSelected(_ siteType: String) -> ImmuTableAction {
        return { [unowned self] row in
            self.tableView.deselectSelectedRowWithAnimation(true)
            let message = "'\(siteType)' selected.\nThis is a work in progress. If you need to create a site, disable the siteCreation feature flag."
            let alertController = UIAlertController(title: nil,
                                                    message: message,
                                                    preferredStyle: .alert)
            alertController.addDefaultActionWithTitle("OK")
            self.present(alertController, animated: true, completion: nil)
        }
    }

    // MARK: - LoginWithLogoAndHelpViewController methods

    func handleHelpButtonTapped(_ sender: AnyObject) {
        displaySupportViewController(sourceTag: .wpComLogin)
    }

    // this VC isn't setup to handle the badge count. Should be fixed when NUXAbstractViewController and LoginViewController are refactored
    func handleHelpshiftUnreadCountUpdated(_ notification: Foundation.Notification) { }

    // MARK: - Misc

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
