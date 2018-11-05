class RevisionsTableViewController: UITableViewController {
    private var dataSource: RevisionsDataSource? {
        didSet {
            self.tableView?.dataSource = dataSource
        }
    }
    private var post: AbstractPost?

    convenience init(post: AbstractPost) {
        self.init()
        self.post = post
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = NSLocalizedString("History", comment: "Title of the post history screen")

        let cellNib = UINib(nibName: "RevisionsTableViewCell", bundle: Bundle(for: RevisionsTableViewCell.self))
        tableView.register(cellNib, forCellReuseIdentifier: RevisionsTableViewCell.reuseIdentifier)

        guard let post = post else {
            return
        }
        dataSource = RevisionsDataSource(post: post)
    }
}

private class RevisionsDataSource: NSObject, UITableViewDataSource {
    let post: AbstractPost
    var revisions: [Int] = []

    init(post: AbstractPost) {
        self.post = post

        super.init()
        fetchRevisions()
    }

    func fetchRevisions() {
        guard let postRevisions = post.revisions as? [Int] else {
            return
        }
        revisions = postRevisions
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return revisions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RevisionsTableViewCell.reuseIdentifier) as? RevisionsTableViewCell else {
            return UITableViewCell()
        }

        cell.revisionNum = revisions[indexPath.row]
        return cell
    }
}
