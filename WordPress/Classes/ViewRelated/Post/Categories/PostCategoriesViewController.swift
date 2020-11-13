import Foundation

@objc protocol PostCategoriesViewControllerDelegate {
    @objc optional func postCategoriesViewController(_ controller: PostCategoriesViewController, didSelectCategory category: PostCategory)
    @objc optional func postCategoriesViewController(_ controller: PostCategoriesViewController, didUpdateSelectedCategories categories: NSSet)
}

@objc enum CategoriesSelectionMode: Int {
    case post
    case parent
    case blogDefault
}

@objc class PostCategoriesViewController: UITableViewController {
   @objc weak var delegate: PostCategoriesViewControllerDelegate?

    var onCategoriesChanged: (() -> Void)?
    var onTableViewHeightDetermined: (() -> Void)?

    private var blog: Blog
    private var originalSelection: [PostCategory]?
    private var selectionMode: CategoriesSelectionMode

    private var categories = [PostCategory]()
    private var categoryIndentationDict = [Int: Int]()
    private var selectedCategories = [PostCategory]()

    private var saveButtonItem: UIBarButtonItem?

    private var hasSyncedCategories = false

    @objc init(blog: Blog, currentSelection: [PostCategory]?, selectionMode: CategoriesSelectionMode) {
        self.blog = blog
        self.selectionMode = selectionMode
        self.originalSelection = currentSelection
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadCategories()
        if !hasSyncedCategories {
            syncCategories()
        }

        preferredContentSize = tableView.contentSize
        onTableViewHeightDetermined?()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onCategoriesChanged?()
    }

    private func configureTableView() {
        tableView.accessibilityIdentifier = "CategoriesList"
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(WPTableViewCell.self, forCellReuseIdentifier: Constants.categoryCellIdentifier)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }

    private func configureView() {
        WPStyleGuide.configureColors(view: view, tableView: tableView)

        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(refreshCategoriesWithInteraction), for: .valueChanged)

        let rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon-post-add"), style: .plain, target: self, action: #selector(showAddNewCategory))

        switch selectionMode {
        case .post:
            navigationItem.rightBarButtonItem = rightBarButtonItem
            title = NSLocalizedString("Post Categories", comment: "Title for selecting categories for a post")
        case .parent:
            navigationItem.rightBarButtonItem = rightBarButtonItem
            title = NSLocalizedString("Parent Category", comment: "Title for selecting parent category of a category")
        case .blogDefault:
            title = NSLocalizedString("Default Category", comment: "Title for selecting a default category for a post")
        }
    }

    @objc private func refreshCategoriesWithInteraction() {
        syncCategories()
    }

    @objc private func showAddNewCategory() {
        guard let addCategoriesViewController = WPAddPostCategoryViewController(blog: blog) else {
            return
        }

        addCategoriesViewController.delegate = self

        let addCategoriesNavigationController = UINavigationController(rootViewController: addCategoriesViewController)
        navigationController?.modalPresentationStyle = .formSheet
        present(addCategoriesNavigationController, animated: true, completion: nil)
    }

    private func syncCategories() {
        guard let context = blog.managedObjectContext else {
            return
        }
        let service  = PostCategoryService(managedObjectContext: context)
        service.syncCategories(for: blog, success: { [weak self] in
            self?.reloadCategories()
            self?.refreshControl?.endRefreshing()
            self?.hasSyncedCategories = true
        }) { [weak self] error in
            self?.refreshControl?.endRefreshing()
        }
    }

    private func reloadCategories() {
        if selectedCategories.isEmpty {
            selectedCategories = originalSelection ?? []
        }

        // Sort categories by parent/child relationship
        let tree = WPCategoryTree(parent: nil)
        tree.getChildrenFromObjects(blog.sortedCategories() ?? [])
        categories = tree.getAllObjects()

        var categoryDict = [Int: PostCategory]()
        categoryIndentationDict = [:]

        categories.forEach { category in
            let categoryID = category.categoryID.intValue
            let parentID = category.parentID.intValue

            categoryDict[categoryID] = category
            let indentationLevel = indentationLevelForCategory(parentID: parentID, categoryCollection: categoryDict)
            categoryIndentationDict[categoryID] = indentationLevel
        }

        // Remove any previously selected category objects that are no longer available.
        let selectedCategories = self.selectedCategories
        self.selectedCategories = selectedCategories.filter { category in
            if let sortedCategories = blog.sortedCategories() as? [PostCategory], sortedCategories.contains(category), !category.isDeleted {
                return true
            }

            return false
        }

        // Notify the delegate of any changes for selectedCategories.
        if selectedCategories.count != self.selectedCategories.count {
            delegate?.postCategoriesViewController?(self, didUpdateSelectedCategories: NSSet(array: self.selectedCategories))
        }

        tableView.reloadData()
    }

    private func indentationLevelForCategory(parentID: Int, categoryCollection: [Int: PostCategory]) -> Int {
        guard parentID != 0, let category = categoryCollection[parentID] else {
            return 0
        }

        return indentationLevelForCategory(parentID: category.parentID.intValue, categoryCollection: categoryCollection) + 1
    }

    private func configureNoCategoryRow(cell: WPTableViewCell) {
        WPStyleGuide.configureTableViewDestructiveActionCell(cell)
        cell.textLabel?.textAlignment = .natural
        cell.textLabel?.text = NSLocalizedString("No Category", comment: "Text shown (to select no-category) in the parent-category-selection screen when creating a new category.")
        if selectedCategories.isEmpty {
            cell.accessoryType = selectedCategories.isEmpty ? .checkmark : .none
        }  else {
            cell.accessoryType = .none
        }
    }

    private func configureRow(for category: PostCategory, cell: WPTableViewCell) {
        let indentationLevel = categoryIndentationDict[category.categoryID.intValue]
        cell.indentationLevel = indentationLevel ?? 0
        cell.indentationWidth = Constants.categoryCellIndentation
        cell.textLabel?.text = category.categoryName.stringByDecodingXMLCharacters()
        WPStyleGuide.configureTableViewCell(cell)
        if selectedCategories.contains(category) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
    }

    //tableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var result = categories.count
        if selectionMode == .parent {
            result = result + 1
        }
        return result
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.categoryCellIdentifier, for: indexPath) as? WPTableViewCell else {
            return UITableViewCell()
        }

        var row = indexPath.row

        // When showing this VC in mode CategoriesSelectionModeParent, we want the first item to be
        // "No Category" and come up in red, to allow the user to select no category at all.
        if selectionMode == .parent {
            if row == 0 {
                configureNoCategoryRow(cell: cell)
                return cell
            } else {
                row = row - 1
            }
        }

        let category = categories[row]
        configureRow(for: category, cell: cell)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let currentSelectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: currentSelectedIndexPath, animated: true)
        }

        var category: PostCategory?
        let row = indexPath.row

        switch selectionMode {
        case .parent:
            if indexPath.row > 0 {
                category = categories[row - 1]
            }
            // If we're choosing a parent category then we're done.
            if let category = category {
                delegate?.postCategoriesViewController?(self, didSelectCategory: category)
                navigationController?.popViewController(animated: true)
            }
        case .post:
            category = categories[row]
            if let category = category {
                if selectedCategories.contains(category),
                    let index = selectedCategories.firstIndex(of: category) {
                    selectedCategories.remove(at: index)
                    tableView.cellForRow(at: indexPath)?.accessoryType = .none
                } else {
                    selectedCategories.append(category)
                    tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
                }

                delegate?.postCategoriesViewController?(self, didUpdateSelectedCategories: NSSet(array: selectedCategories))
            }

        case .blogDefault:
            category = categories[row]
            if let category = category {
                if selectedCategories.contains(category) {
                    return
                }
                selectedCategories.removeAll()
                selectedCategories.append(category)
                tableView.reloadData()
                delegate?.postCategoriesViewController?(self, didSelectCategory: category)
            }
        }
    }
}

private extension PostCategoriesViewController {
    struct Constants {
        static let categoryCellIdentifier = "CategoryCellIdentifier"
        static let categoryCellIndentation = CGFloat(16.0)
    }
}

extension PostCategoriesViewController: WPAddPostCategoryViewControllerDelegate {
    func addPostCategoryViewController(_ controller: WPAddPostCategoryViewController, didAdd category: PostCategory) {
        switch selectionMode {
        case .post, .parent:
            selectedCategories.append(category)
            delegate?.postCategoriesViewController?(self, didUpdateSelectedCategories: NSSet(array: selectedCategories))
        case .blogDefault:
            selectedCategories.removeAll()
            selectedCategories.append(category)
            delegate?.postCategoriesViewController?(self, didSelectCategory: category)
        }

        reloadCategories()
    }
}
