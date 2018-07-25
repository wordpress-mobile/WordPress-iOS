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

        // don't start a tour if it's already completed
        guard let tour = dataSource?.tour(at: indexPath),
            let blog = blog,
            let isCompleted = dataSource?.isCompleted(tour: tour),
            !isCompleted else {
                return
        }

        // make the tour as complete
        let context = ContextManager.sharedInstance().mainContext
        let newCompletion = NSEntityDescription.insertNewObject(forEntityName: QuickStartCompletedTour.entityName(), into: context) as! QuickStartCompletedTour
        newCompletion.blog = blog
        newCompletion.tourID = tour.key

        ContextManager.sharedInstance().saveContextAndWait(ContextManager.sharedInstance().mainContext)

        self.navigationController?.popViewController(animated: true)

        // show the tour
        // - find the tour guide
        if let tabBarController = tabBarController as? WPTabBarController,
            let tourGuide = tabBarController.tourGuide {
            tourGuide.showTestQuickStartNotice()
        }
    }
}

private class QuickStartChecklistDataSource: NSObject, UITableViewDataSource {
    private var blogID: Int
    private var completedTours = Set<String>()

    init(blogID: Int) {
        self.blogID = blogID

        super.init()
        loadCompletedTours()
    }

    func loadCompletedTours() {
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

    // managing tours

    func tour(at indexPath: IndexPath) -> QuickStartTour {
        return QuickStartTourGuide.checklistTours[indexPath.row]
    }

    func isCompleted(tour: QuickStartTour) -> Bool {
        return completedTours.contains(tour.key)
    }

    // UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return QuickStartTourGuide.checklistTours.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: QuickStartChecklistCell.reuseIdentifier) as? QuickStartChecklistCell {
            let tour = QuickStartTourGuide.checklistTours[indexPath.row]
            cell.tour = tour
            if isCompleted(tour: tour) {
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
