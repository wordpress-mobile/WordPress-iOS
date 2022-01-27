import Foundation
import CocoaLumberjack
import WordPressKit
import WordPressShared

class SharePostTypePickerViewController: UITableViewController {

    // MARK: - Public Properties

    var onValueChanged: ((PostType) -> Void)?

    // MARK: - Private Properties

    /// Originally selected post type
    ///
    fileprivate var originallySelectedPostType: PostType

    /// Selected post type
    ///
    fileprivate var selectedPostType: PostType

    /// Apply Bar Button
    ///
    fileprivate lazy var selectButton: UIBarButtonItem = {
        let applyTitle = AppLocalizedString("Select", comment: "Select action on the app extension post type picker screen. Saves the selected post type for the post.")
        let button = UIBarButtonItem(title: applyTitle, style: .plain, target: self, action: #selector(selectWasPressed))
        button.accessibilityIdentifier = "Select Button"
        return button
    }()

    /// Cancel Bar Button
    ///
    fileprivate lazy var cancelButton: UIBarButtonItem = {
        let cancelTitle = AppLocalizedString("Cancel", comment: "Cancel action on the app extension post type picker screen.")
        let button = UIBarButtonItem(title: cancelTitle, style: .plain, target: self, action: #selector(cancelWasPressed))
        button.accessibilityIdentifier = "Cancel Button"
        return button
    }()

    // MARK: - Initializers

    init(postType: PostType) {
        self.originallySelectedPostType = postType
        self.selectedPostType = postType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize Interface
        setupNavigationBar()
        setupTableView()
    }

    // MARK: - Setup Helpers

    fileprivate func setupNavigationBar() {
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = selectButton
    }

    fileprivate func setupTableView() {
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellReuseIdentifier)

        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()

        tableView.reloadData()
    }

    // MARK: - UITableView Overrides

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowCountForPostTypes
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellReuseIdentifier)!
        configurePostTypeCell(cell, indexPath: indexPath)
        return cell
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.defaultRowHeight
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return nil
    }

    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.flashRowAtIndexPath(indexPath,
                                      scrollPosition: .none,
                                      flashLength: Constants.flashAnimationLength,
                                      completion: nil)
        selectedPostTypeTableRowAt(indexPath)
    }
}

// MARK: - Post Type UITableView Helpers

fileprivate extension SharePostTypePickerViewController {
    func configurePostTypeCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        let postType = postTypeForRowAtIndexPath(indexPath)
        cell.textLabel?.text = postType.title
        cell.detailTextLabel?.isEnabled = false
        cell.detailTextLabel?.text = nil
        if selectedPostType == postType {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        WPStyleGuide.Share.configurePostTypeCell(cell)
    }

    var rowCountForPostTypes: Int {
        return PostType.allCases.count
    }

    func selectedPostTypeTableRowAt(_ indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }

        deselectedPostTypeTableRowAt(indexPathForPostType(selectedPostType))

        let postType = postTypeForRowAtIndexPath(indexPath)
        selectedPostType = postType
        cell.accessoryType = .checkmark
    }

    func deselectedPostTypeTableRowAt(_ indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        cell.accessoryType = .none
    }

    func postTypeForRowAtIndexPath(_ indexPath: IndexPath) -> PostType {
        return PostType.allCases[indexPath.row]
    }

    func indexPathForPostType(_ postType: PostType) -> IndexPath {
        let postTypeRow = PostType.allCases.firstIndex(of: postType)!
        return IndexPath(row: postTypeRow, section: 0)
    }
}

// MARK: - Actions

extension SharePostTypePickerViewController {
    @objc func cancelWasPressed() {
        navigationController?.popViewController(animated: true)
    }

    @objc func selectWasPressed() {
        if originallySelectedPostType != selectedPostType {
            onValueChanged?(selectedPostType)
        }
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Constants

fileprivate extension SharePostTypePickerViewController {
    struct Constants {
        static let cellReuseIdentifier  = String(describing: SharePostTypePickerViewController.self)
        static let defaultRowHeight     = CGFloat(44.0)
        static let flashAnimationLength = 0.2
        static let indentationMultiplier = 3
    }
}
