import UIKit

final class SiteTagsViewController: UITableViewController {
    private struct TableConstants {
        static let cellIdentifier = "TagsAdminCell"
        static let accesibilityIdentifier = "SiteTagsList"
        static let numberOfSections = 1
    }
    private let blog: Blog
    private var tags: [PostTag] = []

    fileprivate let noResultsView = WPNoResultsView()

    @objc
    public init(blog: Blog) {
        self.blog = blog
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setAccessibilityIdentifier()
        applyStyleGuide()
        applyTitle()
        configureTable()
        configureNavigationBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        initializeData()
    }

    private func setAccessibilityIdentifier() {
        tableView.accessibilityIdentifier = TableConstants.accesibilityIdentifier
    }

    private func applyStyleGuide() {
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }

    private func applyTitle() {
        title = NSLocalizedString("Tags", comment: "Label for the Tags Section in the Blog Settings")
    }

    private func configureTable() {
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.register(WPTableViewCell.classForCoder(), forCellReuseIdentifier: TableConstants.cellIdentifier)
        setupRefreshControl()
    }

    private func setupRefreshControl() {
        if refreshControl == nil {
            refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(refreshTags), for: .valueChanged)
        }
    }

    @objc private func refreshTags() {
        initializeData()
    }

    private func configureNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(createTag))
    }

    @objc private func createTag() {
        let emptyTag = PostTag()
        navigate(to: emptyTag)
    }

    private func initializeData() {
        let savedTags = blog.tags?.flatMap { return $0 as? PostTag } ?? []
        assign(savedTags)

        let tagsService = PostTagService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        tagsService.syncTags(for: blog, success: { [weak self] tags in
            self?.assign(tags)
        }) { [weak self] error in
            self?.tagsFailedLoading(error: error)
        }
    }

    private func assign(_ data: [PostTag]) {
        tags = data.sorted()
        refreshControl?.endRefreshing()
        refreshNoResultsView()
        tableView.reloadData()
    }
    
    private func refreshNoResultsView() {
        guard tags.count == 0 else {
            noResultsView.removeFromSuperview()
            return
        }
        
        noResultsView.titleText = noResultsTitle()
        noResultsView.accessoryView = noResultsAccessoryView()
        noResultsView.buttonTitle = noResultsButtonTitle()
        
        if noResultsView.superview == nil {
            tableView.addSubview(withFadeAnimation: noResultsView)
        }
    }

    func tagsFailedLoading(error: Error) {
        DDLogError("Tag management. Error loading tags for \(String(describing: blog.url)): \(error)")
    }
}

extension SiteTagsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return TableConstants.numberOfSections
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tags.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TableConstants.cellIdentifier, for: indexPath)

        cell.textLabel?.text = tags[indexPath.row].name
        
        return cell
    }
}

extension SiteTagsViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTag = tags[indexPath.row]        
        navigate(to: selectedTag)
    }
}

extension SiteTagsViewController {
    fileprivate func navigate(to tag: PostTag) {
        let singleTag = SiteTagViewController(blog: blog, tag: tag)
        navigationController?.pushViewController(singleTag, animated: true)
    }
}

extension SiteTagsViewController {
    fileprivate func noResultsTitle() -> String {
        return NSLocalizedString("No Tags Yet", comment: "Empty state. Tags management (Settings > Writing > Tags)")
    }

    fileprivate func noResultsAccessoryView() -> UIView {
        return UIImageView(image: UIImage(named: "illustration-posts"))
    }

    fileprivate func noResultsButtonTitle() -> String {
        return NSLocalizedString("Add New Tag", comment: "Title of the button in the placeholder for an empty list of blog tags.")
    }
}
