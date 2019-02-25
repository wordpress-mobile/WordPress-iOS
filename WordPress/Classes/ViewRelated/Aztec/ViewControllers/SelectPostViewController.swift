import UIKit


class SelectPostViewController: UITableViewController {

    typealias SelectPostCallback = (_ url: String, _ title: String) -> ()
    private var callback: SelectPostCallback?

    private var blog: Blog!
    private var selectedLink: String?

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        return searchController
    }()

    private lazy var fetchController: NSFetchedResultsController<AbstractPost> = {
        return PostCoordinator.shared.posts(for: self.blog, wichTitleContains: "")
    }()

    // MARK: - Initialization

    init(blog: Blog, selectedLink: String? = nil, callback: SelectPostCallback? = nil) {
        self.blog = blog
        self.selectedLink = selectedLink
        self.callback = callback
        super.init(style: .plain)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
        if post is Page {
            cell.detailTextLabel?.text = NSLocalizedString("Page", comment: "Noun. Type of content being selected is a blog page")
        } else {
            cell.detailTextLabel?.text = NSLocalizedString("Post", comment: "Noun. Type of content being selected is a blog post")
        }
        if post.permaLink == selectedLink {
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
        guard let title = post.titleForDisplay(), let url = post.permaLink else {
            return
        }

        callback?(url, title)
    }
}


// MARK: - UISearchResultsUpdating Conformance
//
extension SelectPostViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        fetchController = PostCoordinator.shared.posts(for: blog, wichTitleContains: searchText)
        tableView.reloadData()
    }
}
