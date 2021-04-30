import UIKit


class SelectPostViewController: UITableViewController {

    typealias SelectPostCallback = (AbstractPost) -> ()
    private var callback: SelectPostCallback?

    private var blog: Blog!
    private var isSelectedPost: ((AbstractPost) -> Bool)? = nil

    /// If the cell should display the post type in the `detailTextLabel`
    private var showsPostType: Bool = true

    /// An entity to fetch which is of type `AbstractPost`
    private let entityName: String?

    /// The IDs of posts which should be hidden from the list
    private let hiddenPosts: [Int]

    /// Only include pubilished posts
    private let publishedOnly: Bool

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        return searchController
    }()

    private lazy var fetchController: NSFetchedResultsController<AbstractPost> = {
        return PostCoordinator.shared.posts(for: blog, containsTitle: "", excludingPostIDs: hiddenPosts, entityName: entityName, publishedOnly: publishedOnly)
    }()

    // MARK: - Initialization

    init(blog: Blog,
         isSelectedPost: ((AbstractPost) -> Bool)? = nil,
         showsPostType: Bool = true,
         entityName: String? = nil,
         hiddenPosts: [Int] = [],
         publishedOnly: Bool = false,
         callback: SelectPostCallback? = nil) {
        self.blog = blog
        self.isSelectedPost = isSelectedPost
        self.callback = callback
        self.showsPostType = showsPostType
        self.entityName = entityName
        self.hiddenPosts = hiddenPosts
        self.publishedOnly = publishedOnly
        super.init(style: .plain)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableHeaderView = searchController.searchBar
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchController.dismiss(animated: false, completion: nil)
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension SelectPostViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let count =  fetchController.sections?.count else {
            return 0
        }

        return count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = self.fetchController.sections else {
            return 0
        }

        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var reusableCell = tableView.dequeueReusableCell(withIdentifier: "PostCell")
        if reusableCell == nil {
            reusableCell = UITableViewCell(style: .subtitle, reuseIdentifier: "PostCell")
            WPStyleGuide.configureTableViewCell(reusableCell)
        }
        guard let cell = reusableCell else {
            preconditionFailure("Unable to create cell!")
        }

        let post = fetchController.object(at: indexPath)
        cell.textLabel?.text = post.titleForDisplay()
        if showsPostType {
            if post is Page {
                cell.detailTextLabel?.text = NSLocalizedString("Page", comment: "Noun. Type of content being selected is a blog page")
            } else {
                cell.detailTextLabel?.text = NSLocalizedString("Post", comment: "Noun. Type of content being selected is a blog post")
            }
        }
        if isSelectedPost?(post) == true {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension SelectPostViewController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = fetchController.object(at: indexPath)
        callback?(post)
    }
}


// MARK: - UISearchResultsUpdating Conformance
//
extension SelectPostViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        fetchController = PostCoordinator.shared.posts(for: blog, containsTitle: searchText, excludingPostIDs: hiddenPosts, entityName: entityName, publishedOnly: publishedOnly)
        tableView.reloadData()
    }
}
