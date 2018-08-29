import UIKit

class SelectPostViewController: UITableViewController, UISearchResultsUpdating {

    private var blog: Blog!

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

    typealias SelectPostCallback = (_ url: String, _ title: String) -> ()

    private var callback: SelectPostCallback?

    init(blog: Blog, callback: SelectPostCallback? = nil) {
        self.blog = blog
        self.callback = callback
        super.init(style: .plain)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.tableHeaderView = searchController.searchBar
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PostCell")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if let count =  fetchController.sections?.count {
            return count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = self.fetchController.sections else {
            return 0
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath)

        cell.textLabel?.text = fetchController.object(at: indexPath).titleForDisplay()

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let post = fetchController.object(at: indexPath)
        guard let title = post.titleForDisplay(), let url = post.permaLink else {
            return
        }

        callback?(url, title)
    }

    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        fetchController = PostCoordinator.shared.posts(for: self.blog, wichTitleContains: searchText)
        self.tableView.reloadData()
    }
}
