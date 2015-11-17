import UIKit

class MyProfileViewController: UITableViewController {
    static let cellIdentifier = "MyProfileCell"

    var viewModel = ImmuTable(sections: []) {
        didSet {
            if isViewLoaded() {
                tableView.reloadData()
            }
        }
    }

    var account: WPAccount! {
        didSet {
            buildViewModel()
        }
    }

    // MARK: - Table View Controller

    required convenience init() {
        self.init(style: .Grouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("My Profile", comment: "My Profile view title")

        // TODO: identifier should be based on cell class, not controller (@koke 2015-11-17)
        tableView.registerClass(WPTableViewCellValue1.self, forCellReuseIdentifier: MyProfileViewController.cellIdentifier)
        WPStyleGuide.resetReadableMarginsForTableView(tableView)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }

    // MARK: - View Model

    func buildViewModel() {
        let firstNameRow = ImmuTable.TextField(
            title: NSLocalizedString("First Name", comment: "My Profile first name label"),
            value: "",
            action: editFirstName)

        let lastNameRow = ImmuTable.TextField(
            title: NSLocalizedString("Last Name", comment: "My Profile last name label"),
            value: "",
            action: editLastName)

        let displayNameRow = ImmuTable.TextField(
            title: NSLocalizedString("Display Name", comment: "My Profile display name label"),
            value: account.displayName,
            action: editDisplayName)

        let aboutMeRow = ImmuTable.TextField(
            title: NSLocalizedString("About Me", comment: "My Profile 'About me' label"),
            value: "",
            action: editAboutMe)

        viewModel =  ImmuTable(sections: [
            ImmuTable.Section(rows: [
                firstNameRow,
                lastNameRow,
                displayNameRow,
                aboutMeRow
                ])
            ])
    }

    // MARK: - Cell Actions

    func editFirstName() {
        // TODO: to be implemented (@koke 2015-11-17)
    }

    func editLastName() {
        // TODO: to be implemented (@koke 2015-11-17)
    }

    func editDisplayName() {
        // TODO: to be implemented (@koke 2015-11-17)
    }

    func editAboutMe() {
        // TODO: to be implemented (@koke 2015-11-17)
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MyProfileViewController.cellIdentifier, forIndexPath: indexPath)
        let row = viewModel.rowAtIndexPath(indexPath)

        cell.textLabel?.text = row.title
        cell.detailTextLabel?.text = row.detail
        cell.imageView?.image = row.icon

        // TODO: this should be based on the row type (@koke 2015-11-17)
        cell.accessoryType = .DisclosureIndicator

        WPStyleGuide.configureTableViewCell(cell)

        return cell
    }

}
