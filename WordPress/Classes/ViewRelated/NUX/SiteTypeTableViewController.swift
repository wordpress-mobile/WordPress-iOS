import UIKit

class SiteTypeTableViewController: UITableViewController {

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
        ImmuTable.registerRows([InstructionRow.self], tableView: tableView)
        tableHandler = ImmuTableViewHandler(takeOver: self)
        tableHandler.viewModel = tableViewModel()
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
    }
    
    func setupNavBar() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                           target: self,
                                           action: #selector(handleCancelButtonTapped))
        navigationItem.leftBarButtonItem = cancelButton
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
        
        return ImmuTable(sections: [
            ImmuTableSection(
                rows: [
                    instructionRow
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
