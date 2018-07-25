class QuickStartChecklistView: UITableViewController {
    private var dataSource: QuickStartChecklistDataSource? {
        didSet {
            self.tableView?.dataSource = dataSource
        }
    }
    @objc public var blog: Blog? {
        didSet {
            guard let dotComID = blog?.dotComID else {
                return
            }
            dataSource = QuickStartChecklistDataSource(blogID: dotComID.intValue)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tableView = UITableView(frame: .zero)
        self.tableView = tableView

        let cellNib = UINib(nibName: "QuickStartChecklistCell", bundle: Bundle(for: QuickStartChecklistCell.self))
        tableView.register(cellNib, forCellReuseIdentifier: QuickStartChecklistCell.reuseIdentifier)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = dataSource?.tableView(tableView, cellForRowAt: indexPath) as? QuickStartChecklistCell,
            let tour = cell.tour,
            let blog = blog {
            let context = ContextManager.sharedInstance().mainContext
            let newCompletion = NSEntityDescription.insertNewObject(forEntityName: QuickStartCompletedTour.entityName(), into: context) as! QuickStartCompletedTour
            newCompletion.blog = blog
            newCompletion.tourID = tour.key

            ContextManager.sharedInstance().saveContextAndWait(ContextManager.sharedInstance().mainContext)

            self.navigationController?.popViewController(animated: true)
        }
    }
}

private class QuickStartChecklistDataSource: NSObject, UITableViewDataSource {
    private var blogID: Int
    private var completedTours = Set<String>()

    init(blogID: Int) {
        self.blogID = blogID

        super.init()
        getCompletedTours()
    }

    func getCompletedTours() {
        let context = ContextManager.sharedInstance().mainContext
        let fetchRequest = NSFetchRequest<QuickStartCompletedTour>(entityName: QuickStartCompletedTour.entityName())
        fetchRequest.predicate = NSPredicate(format: "blog.blogID = %d", blogID)

        guard let results = try? context.fetch(fetchRequest) else {
            return
        }

        for result in results {
            completedTours.insert(result.tourID)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return QuickStartTourGuide.checklistTours.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: QuickStartChecklistCell.reuseIdentifier) as? QuickStartChecklistCell {
            let tour = QuickStartTourGuide.checklistTours[indexPath.row]
            cell.tour = tour
            if completedTours.contains(tour.key) {
                cell.completed = true
            }
            return cell
        }
        return UITableViewCell()
    }

    private enum Keys: String {
        case quickStartTourProgress = "quickStartTourProgress"
    }
}
