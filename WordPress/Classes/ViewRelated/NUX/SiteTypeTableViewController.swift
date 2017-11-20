import UIKit

class SiteTypeTableViewController: UITableViewController, LoginWithLogoAndHelpViewController {

    // MARK: - Properties
    
    fileprivate var tableHandler: ImmuTableViewHandler!
    
    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
        setupNavBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableHandler.viewModel = tableViewModel()
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
    }
    
    // MARK: - Handle Nav Bar Actions
    
    func handleCancelButtonTapped(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table Model
    
    private func tableViewModel() -> ImmuTable {
        
        let step = NSLocalizedString("STEP 1 OF 4", comment: "Step for view.")
        let instr1 = NSLocalizedString("What kind of site do you need?", comment: "Site type question.")
        let instr2 = NSLocalizedString("Choose an option below:", comment: "Choose site type prompt.")
        let instructionRow = InstructionRow(step: step, instr1: instr1, instr2: instr2, action: nil)
        
        // TODO - add images
        
        let blog = NSLocalizedString("Start with a Blog", comment: "Start with site type.")
        let blogDescr = NSLocalizedString("To share your ideas, stories and photographs with your followers.", comment: "Site type description.")
        let blogRow = SiteTypeRow(startWith: blog, typeDescr: blogDescr, typeImage: nil, action: nil)

        let website = NSLocalizedString("Start with a Website", comment: "Start with site type.")
        let websiteDescr = NSLocalizedString("To promote your business or brand, and connect with your audience.", comment: "Site type description.")
        let websiteRow = SiteTypeRow(startWith: website, typeDescr: websiteDescr, typeImage: nil, action: nil)
        
        let portfolio = NSLocalizedString("Start with a Portfolio", comment: "Start with site type.")
        let portfolioDescr = NSLocalizedString("To present your creative projects in a visual showcase.", comment: "Site type description.")
        let portfolioRow = SiteTypeRow(startWith: portfolio, typeDescr: portfolioDescr, typeImage: nil, action: nil)
        
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
