import Foundation
import CocoaLumberjack
import WordPressKit
import WordPressShared

struct SiteCategories {
    var siteID: Int
    var allCategories: [RemotePostCategory]?
    var selectedCategories: [RemotePostCategory]?
    var defaultCategoryID: NSNumber?
}

class ShareCategoriesPickerViewController: UITableViewController {

    // MARK: - Public Properties

    var onValueChanged: ((SiteCategories) -> Void)?

    // MARK: - Private Properties

    /// All availible categories for selected site
    ///
    fileprivate var allCategories: [RemotePostCategory]?

    /// Originally selected categories
    ///
    fileprivate var originallySelectedCategories: [RemotePostCategory]

    /// Selected categories
    ///
    fileprivate var selectedCategories: [RemotePostCategory]

    /// SiteID to fetch categories for
    ///
    fileprivate let siteID: Int

    /// Default category ID
    ///
    fileprivate let defaultCategoryID: NSNumber?

    /// Apply Bar Button
    ///
    fileprivate lazy var selectButton: UIBarButtonItem = {
        let applyTitle = NSLocalizedString("Select", comment: "Select action on the app extension category picker screen. Saves the selected categories for the post.")
        let button = UIBarButtonItem(title: applyTitle, style: .plain, target: self, action: #selector(selectWasPressed))
        button.accessibilityIdentifier = "Select Button"
        return button
    }()

    /// Cancel Bar Button
    ///
    fileprivate lazy var cancelButton: UIBarButtonItem = {
        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel action on the app extension category picker screen.")
        let button = UIBarButtonItem(title: cancelTitle, style: .plain, target: self, action: #selector(cancelWasPressed))
        button.accessibilityIdentifier = "Cancel Button"
        return button
    }()

    /// Activity spinner used when loading sites
    ///
    fileprivate lazy var loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    /// No results view
    ///
    @objc lazy var noResultsView: WPNoResultsView = {
        let title = NSLocalizedString("No available Categories", comment: "A short message that informs the user no categories could be loaded in the share extension.")
        return WPNoResultsView(title: title, message: nil, accessoryView: nil, buttonTitle: nil)
    }()

    /// Loading view
    ///
    @objc lazy var loadingView: WPNoResultsView = {
        let title = NSLocalizedString("Fetching Categories...", comment: "A short message to inform the user data for their categories are being fetched.")
        return WPNoResultsView(title: title, message: nil, accessoryView: loadingActivityIndicatorView, buttonTitle: nil)
    }()

    // MARK: - Initializers

    init(categoryInfo: SiteCategories) {
        self.siteID = categoryInfo.siteID
        self.defaultCategoryID = categoryInfo.defaultCategoryID
        self.allCategories = categoryInfo.allCategories ?? []

        // Add the default site to the selected list if it's empty.
        var selected = categoryInfo.selectedCategories ?? []
        if selected.isEmpty, let defaultCategory = categoryInfo.allCategories?.filter({$0.categoryID == categoryInfo.defaultCategoryID }).first {
            selected.append(defaultCategory)
        }
        self.selectedCategories = selected
        self.originallySelectedCategories = selected
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
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellReuseIdentifier)
        tableView.allowsMultipleSelection = true

        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()

        tableView.reloadData()
    }

    // MARK: - UITableView Overrides

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowCountForCategories
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellReuseIdentifier)!
        configureCategoryCell(cell, indexPath: indexPath)
        return cell
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.defaultRowHeight
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionHeader(view)
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return nil
    }

    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.flashRowAtIndexPath(indexPath, scrollPosition: .none, flashLength: Constants.flashAnimationLength, completion: nil)
        selectedCategoryTableRowAt(indexPath)
    }
}

// MARK: - Category UITableView Helpers

fileprivate extension ShareCategoriesPickerViewController {
    func configureCategoryCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        guard let category = categoryForRowAtIndexPath(indexPath) else {
            return
        }

        cell.textLabel?.text = category.name.nonEmptyString()
        cell.detailTextLabel?.isEnabled = false
        cell.detailTextLabel?.text = nil
        let selectedCategory = selectedCategories.contains(where: { $0.categoryID == category.categoryID })
        if selectedCategory {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        WPStyleGuide.Share.configureTableViewSiteCell(cell)
    }

    var rowCountForCategories: Int {
        guard let allCategories = allCategories else {
            return 0
        }
        return allCategories.count
    }

    func selectedCategoryTableRowAt(_ indexPath: IndexPath) {
        guard let category = categoryForRowAtIndexPath(indexPath),
            let cell = tableView.cellForRow(at: indexPath) else {
            return
        }

        let selectedCategory = selectedCategories.contains(where: { $0.categoryID == category.categoryID })
        if selectedCategory {
            selectedCategories = selectedCategories.filter { $0.categoryID != category.categoryID }
            cell.accessoryType = .none
        } else {
            selectedCategories.append(category)
            cell.accessoryType = .checkmark
        }
    }

    func categoryForRowAtIndexPath(_ indexPath: IndexPath) -> RemotePostCategory? {
        guard let allCategories = allCategories else {
            return nil
        }
        return allCategories[indexPath.row]
    }

    func clearCategoryDataAndRefreshSitesTable() {
        allCategories = nil
        tableView.reloadData()
    }
}

// MARK: - Actions

extension ShareCategoriesPickerViewController {
    @objc func cancelWasPressed() {
        _ = navigationController?.popViewController(animated: true)
    }

    @objc func selectWasPressed() {
        if originallySelectedCategories != selectedCategories {
            let categoryInfo = SiteCategories(siteID: siteID, allCategories: allCategories, selectedCategories: selectedCategories, defaultCategoryID: defaultCategoryID)
            onValueChanged?(categoryInfo)
        }
        _ = navigationController?.popViewController(animated: true)
    }
}

// MARK: - Backend Interaction

fileprivate extension ShareCategoriesPickerViewController {
    // FIXME: Pull to refresh
    func loadCategories() {
        let service = AppExtensionsService()
        service.fetchCategoriesForSite(siteID, onSuccess: { categories in
            let categories = categories.flatMap { return $0 }
            self.allCategories = categories
        }, onFailure: { error in
            self.categoriesFailedLoading(error)
        })
    }

    func categoriesFailedLoading(_ error: Error?) {
        if let error = error {
            DDLogError("Error loading categories: \(error)")
        }
        // FIXME: e.g. dataSource = FailureDataSource()
    }
}

// MARK: - Constants

fileprivate extension ShareCategoriesPickerViewController {
    struct Constants {
        static let cellReuseIdentifier  = String(describing: ShareCategoriesPickerViewController.self)
        static let defaultRowHeight     = CGFloat(44.0)
        static let flashAnimationLength = 0.2
    }
}
