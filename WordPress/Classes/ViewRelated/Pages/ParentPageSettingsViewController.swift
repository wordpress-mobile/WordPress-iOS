import UIKit


class ParentPageSettingsViewController: UIViewController {
    private struct Section {
        var rows: [Row]
    }

    private struct Row {
        struct Constants {
            static let identifier = "CheckmarkCellIdentifier"
        }

        enum RowType {
            case topLevel
            case child
        }

        var page: Page?
        var type: RowType
        var title: String {
            switch type {
            case .topLevel: return NSLocalizedString("Top level", comment: "Cell title for the Top Level option case")
            case .child: return page?.postTitle ?? ""
            }
        }
    }


    @IBOutlet private var cancelButton: UIBarButtonItem!
    @IBOutlet private var doneButton: UIBarButtonItem!
    @IBOutlet private var tableView: UITableView!

    private let postService = PostService(managedObjectContext: ContextManager.sharedInstance().mainContext)
    private var originalIndex: IndexPath?
    private var selectedIndex: IndexPath? {
        didSet {
            doneButton.isEnabled = selectedIndex != originalIndex
        }
    }

    private var sections: [Section]!
    private var selectedPage: Page!


    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }


    func set(pages: [Page], for page: Page) {
        selectedPage = page
        selectedIndex = selectedPage.isTopLevelPage ? IndexPath(row: 0, section: 0) : nil
        originalIndex = selectedIndex

        let rows = pages.map { Row(page: $0, type: .child) }
        sections = [Section(rows: [Row(page: nil, type: .topLevel)]),
                    Section(rows: rows)]
    }


    // MARK: - Private methods

    private func setupUI() {
        navigationItem.title = NSLocalizedString("Set Parent", comment: "Navigation title displayed on the navigation bar")

        cancelButton.title = NSLocalizedString("Cancel", comment: "Text displayed by the left navigation button title")
        doneButton.title = NSLocalizedString("Done", comment: "Text displayed by the right navigation button title")

        WPStyleGuide.setRightBarButtonItemWithCorrectSpacing(doneButton, for: navigationItem)
        WPStyleGuide.setLeftBarButtonItemWithCorrectSpacing(cancelButton, for: navigationItem)

        setupTableView()
    }

    private func setupTableView() {
        // Register the cells
        tableView.register(CheckmarkTableViewCell.self, forCellReuseIdentifier: Row.Constants.identifier)

        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()

        // Style!
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)

        tableView.dataSource = self
        tableView.delegate = self
    }

    private func reloadData(at section: Int, animation: UITableViewRowAnimation = .none) {
        let sections = IndexSet(integer: section)
        tableView.reloadSections(sections, with: animation)
    }


    // MARK: IBAction

    @IBAction func doneAction(_ sender: UIBarButtonItem) {
    }

    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}


extension ParentPageSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell: CheckmarkTableViewCell = self.cell(for: tableView, at: indexPath, identifier: Row.Constants.identifier)
        cell.title = row.title
        cell.on = selectedIndex == indexPath
        return cell
    }

    private func cell<T: UITableViewCell>(for tableView: UITableView, at indexPath: IndexPath, identifier: String) -> T {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? T else {
            fatalError("A cell must be found for identifier: \(identifier)")
        }
        return cell
    }
}


extension ParentPageSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = sections[indexPath.section].rows[indexPath.row]

        if indexPath == selectedIndex {
            return
        }

        selectedIndex = indexPath
        tableView.reloadData()
    }
}


/// ParentPageSettingsViewController class constructor
//
extension ParentPageSettingsViewController {
    class func navigationController(with pages: [Page], selectedPage: Page) -> UINavigationController {
        let storyBoard = UIStoryboard(name: "Pages", bundle: Bundle.main)
        guard let controller = storyBoard.instantiateViewController(withIdentifier: "ParentPageSettings") as? UINavigationController else {
            fatalError("A navigation view controller is required for Parent Page Settings")
        }
        guard let parentPageSettingsViewController = controller.viewControllers.first as? ParentPageSettingsViewController else {
            fatalError("A ParentPageSettingsViewController is required for Parent Page Settings")
        }
        parentPageSettingsViewController.set(pages: pages, for: selectedPage)
        return controller
    }
}
