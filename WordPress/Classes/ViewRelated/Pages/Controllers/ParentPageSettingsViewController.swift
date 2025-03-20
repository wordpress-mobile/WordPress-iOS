import UIKit
import WordPressUI

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
        case .child: return page?.titleForDisplay() ?? ""
        }
    }

    init(page: Page? = nil, type: RowType = .topLevel) {
        self.page = page
        self.type = type
    }

    func configureCell(_ cell: UITableViewCell) {
        if let label = cell.textLabel {
            WPStyleGuide.configureLabel(label, textStyle: .body)
        }
        let cell = cell as! CheckmarkTableViewCell
        cell.title = title
    }
}

class ParentPageSettingsViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var searchBar: UISearchBar!

    private lazy var noResultsViewController = NoResultsViewController.controller()
    private var isSearching = false
    private var sections: [ImmuTableSection] {
        guard let text = searchBar.text else {
            return rows
        }
        return isSearching && !text.isEmpty ? filteredRows : rows
    }
    private var rows: [ImmuTableSection]!
    private var filteredRows: [ImmuTableSection]!
    private var selectedPage: Page!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        startListeningToKeyboardNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stopListeningToKeyboardNotifications()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        WPAnalytics.track(.pageSetParentViewed)
    }

    func set(pages: [Page], for page: Page) {
        selectedPage = page

        filteredRows = []

        let rows = pages.map { Row(page: $0, type: .child) }
        self.rows = [ImmuTableSection(rows: [Row()]),
                     ImmuTableSection(headerText: NSLocalizedString("Pages", comment: "This is the section title"), rows: rows)]
    }

    // MARK: - Private methods

    private func setupUI() {
        navigationItem.title = NSLocalizedString("parentPageSettings.title", value: "Parent Page", comment: "Navigation title displayed on the navigation bar")

        searchBar.delegate = self

        WPStyleGuide.configureSearchBar(searchBar)

        setupTableView()
    }

    private func setupTableView() {
        // Register the cells
        tableView.register(Row.cell, cellReuseIdentifier: Row.cell.reusableIdentifier)

        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()

        // Style!
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)

        tableView.dataSource = self
        tableView.delegate = self
    }

    private func startListeningToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidShow),
                                               name: UIResponder.keyboardDidShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    private func stopListeningToKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardDidShow(_ notification: Foundation.Notification) {
        let keyboardFrame = localKeyboardFrameFromNotification(notification)
        let keyboardHeight = tableView.frame.maxY - keyboardFrame.origin.y

        tableView.contentInset.bottom = keyboardHeight
    }

    @objc private func keyboardWillHide(_ notification: Foundation.Notification) {
        tableView.contentInset.bottom = 0
    }

    private func localKeyboardFrameFromNotification(_ notification: Foundation.Notification) -> CGRect {
        let key = UIResponder.keyboardFrameEndUserInfoKey
        guard let keyboardFrame = (notification.userInfo?[key] as? NSValue)?.cgRectValue else {
            return .zero
        }

        return view.convert(keyboardFrame, from: nil)
    }

    private func triggerNoResults(display: Bool) {
        if display {
            if noResultsViewController.view.superview != nil {
                return
            }

            noResultsViewController.configureForNoSearchResults(title: NSLocalizedString("No pages matching your search",
                                                                                         comment: "Text displayed when there's no matching with the text search"))

            addChild(noResultsViewController)
            noResultsViewController.view.frame = tableView.frame
            noResultsViewController.view.frame.origin.y = 0

            tableView.addSubview(withFadeAnimation: noResultsViewController.view)
            noResultsViewController.didMove(toParent: self)
        } else {
            if noResultsViewController.view.superview == nil {
                return
            }

            noResultsViewController.removeFromView()
        }
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
        guard let row = sections[indexPath.section].rows[indexPath.row] as? Row else {
            fatalError("A row must be found")
        }

        let cell: CheckmarkTableViewCell = self.cell(for: tableView, at: indexPath, identifier: row.reusableIdentifier)
        cell.on = row.page?.postID == selectedPage.parentID
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
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].headerText
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let row = sections[indexPath.section].rows[indexPath.row] as? Row else {
            return
        }
        selectedPage.parentID = row.page?.postID
        tableView.reloadData()
    }
}

/// ParentPageSettingsViewController class constructor
//
extension ParentPageSettingsViewController {
    class func make(with pages: [Page], selectedPage: Page) -> UIViewController {
        let storyboard = UIStoryboard(name: "Pages", bundle: Bundle.main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "ParentPageSettings") as? ParentPageSettingsViewController else {
            fatalError("A ParentPageSettingsViewController view controller is required for Parent Page Settings")
        }
        viewController.set(pages: pages, for: selectedPage)
        return viewController
    }
}

extension ParentPageSettingsViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isSearching = true
        searchBar.showsCancelButton = true
        WPAnalytics.track(.pageSetParentSearchAccessed)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        isSearching = false
        tableView.reloadData()
        searchBar.showsCancelButton = false
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearching = false
        triggerNoResults(display: false)
        tableView.reloadData()
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        searchBar.text = nil
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let rows = rows.last?.rows as? [Row] else {
            return
        }

        let filteredRows = rows.filter { $0.title.lowercased().contains(searchText.lowercased()) }
        self.filteredRows = searchText.isEmpty ? self.rows : [ImmuTableSection(rows: filteredRows)]

        triggerNoResults(display: filteredRows.isEmpty && !searchText.isEmpty)

        tableView.reloadData()
    }
}
