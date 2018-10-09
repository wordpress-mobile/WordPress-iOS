import UIKit


private struct Row: ImmuTableRow {
    static let cell = ImmuTableCell.class(CheckmarkTableViewCell.self)

    enum RowType {
        case topLevel
        case child
    }

    var action: ImmuTableAction?
    var page: Page?
    var type: RowType
    var title: String {
        switch type {
        case .topLevel: return NSLocalizedString("Top level", comment: "Cell title for the Top Level option case")
        case .child: return page?.postTitle ?? ""
        }
    }
    var titleFont: UIFont {
        switch type {
        case .topLevel: return UIFont.systemFont(ofSize: 16.0)
        case .child: return WPFontManager.notoRegularFont(ofSize: 17)
        }
    }


    init(page: Page? = nil, type: RowType = .topLevel) {
        self.page = page
        self.type = type
    }

    func configureCell(_ cell: UITableViewCell) {
        let cell = cell as! CheckmarkTableViewCell
        cell.textLabel?.font = titleFont
        cell.title = title
    }
}


class ParentPageSettingsViewController: UIViewController {
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

    private var sections: [ImmuTableSection]!
    private var selectedPage: Page!
    private var selectedParentId: NSNumber? {
        guard let selectedIndex = selectedIndex,
            let row = sections[selectedIndex.section].rows[selectedIndex.row] as? Row else {
            return nil
        }
        return row.page?.postID
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }


    func set(pages: [Page], for page: Page) {
        selectedPage = page
        originalIndex = originalIndexPath(with: pages)
        selectedIndex = originalIndex

        let rows = pages.map { Row(page: $0, type: .child) }
        sections = [ImmuTableSection(rows: [Row()]),
                    ImmuTableSection(headerText: NSLocalizedString("Pages", comment: "This is the section title"), rows: rows)]
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
        tableView.register(Row.cell, cellReuseIdentifier: Row.cell.reusableIdentifier)

        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()

        // Style!
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)

        tableView.dataSource = self
        tableView.delegate = self
    }

    private func reloadData(at section: Int, animation: UITableView.RowAnimation = .none) {
        let sections = IndexSet(integer: section)
        tableView.reloadSections(sections, with: animation)
    }

    private func updatePage(_ completion: ((_ page: AbstractPost?, _ error: Error?) -> Void)?) {
        postService.uploadPost(selectedPage, success: { uploadedPost in
            completion?(uploadedPost, nil)
        }) { error in
            completion?(nil, error)
        }
    }

    private func originalIndexPath(with pages: [Page]) -> IndexPath? {
        if selectedPage.isTopLevelPage {
            return IndexPath(row: 0, section: 0)
        }

        guard let parent = (pages.first { $0.postID == selectedPage.parentID }),
            let index = pages.index(of: parent) else {
            return nil
        }

        return IndexPath(row: index, section: 1)
    }


    // MARK: IBAction

    @IBAction func doneAction(_ sender: UIBarButtonItem) {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show(withStatus: NSLocalizedString("Updating...",
                                                         comment: "Text displayed in HUD while a draft or scheduled post is being updated."))
        let parentId: NSNumber? = selectedPage.parentID
        selectedPage.parentID = selectedParentId
        updatePage { [weak self] (_, error) in
            SVProgressHUD.dismiss()

            if let error = error {
                DDLogError("Error publishing post: \(error.localizedDescription)")
                SVProgressHUD.showDismissibleError(withStatus: NSLocalizedString("Error occurred\nduring saving",
                                                                                 comment: "Text displayed in HUD after attempting to save a draft post and an error occurred."))
                self?.selectedPage.parentID = parentId
            } else {
                self?.dismiss(animated: true, completion: nil)
            }
        }
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
        let cell: CheckmarkTableViewCell = self.cell(for: tableView, at: indexPath, identifier: row.reusableIdentifier)
        cell.on = selectedIndex == indexPath
        row.configureCell(cell)
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
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionHeader(view)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].headerText
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
