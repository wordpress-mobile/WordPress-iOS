class QuickStartChecklistViewController: UITableViewController {
    private var dataSource: QuickStartChecklistDataSource? {
        didSet {
            self.tableView?.dataSource = dataSource
        }
    }
    private var blog: Blog?
    private var observer: NSObjectProtocol?
    private var service: SiteManagementService!

    @objc
    convenience init(blog: Blog) {
        self.init()
        self.blog = blog

        startObservingForQuickStart()
    }

    deinit {
        stopObservingForQuickStart()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tableView = UITableView(frame: .zero)
        if #available(iOS 11, *) {
            tableView.estimatedRowHeight = UITableView.automaticDimension
        } else {
            tableView.estimatedRowHeight = WPTableViewDefaultRowHeight
        }

        self.tableView = tableView

        let cellNib = UINib(nibName: "QuickStartChecklistCell", bundle: Bundle(for: QuickStartChecklistCell.self))
        tableView.register(cellNib, forCellReuseIdentifier: QuickStartChecklistCell.reuseIdentifier)

        service = SiteManagementService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        guard let blog = blog else {
            return
        }

        dataSource = QuickStartChecklistDataSource(blog: blog) { [weak self] isChecklistCompleted in
            if isChecklistCompleted {
                self?.markQuickStartChecklistAsComplete()
            }
        }
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let tour = dataSource?.tour(at: indexPath),
            !(tour is QuickStartCreateTour) else {
                return nil
        }
        return indexPath
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tour = dataSource?.tour(at: indexPath),
            let blog = blog else {
                return
        }

        guard let tourGuide = QuickStartTourGuide.find() else {
            return
        }

        tourGuide.start(tour: tour, for: blog)

        self.navigationController?.popViewController(animated: true)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    private func startObservingForQuickStart() {
        observer = NotificationCenter.default.addObserver(forName: .QuickStartTourElementChangedNotification, object: nil, queue: nil) { [weak self] (notification) in
            guard let userInfo = notification.userInfo,
                let element = userInfo[QuickStartTourGuide.notificationElementKey] as? QuickStartTourElement,
                element == .tourCompleted else {
                    return
            }

            self?.dataSource?.loadCompletedTours()
            self?.tableView.reloadData()
        }
    }

    private func stopObservingForQuickStart() {
        NotificationCenter.default.removeObserver(observer as Any)
    }

    private func markQuickStartChecklistAsComplete() {
        guard let blog = blog else {
            return
        }
        service.markQuickStartChecklistAsComplete(for: blog) { (success, error) in
            if !success {
                // Store blog for future check?
            }
        }
    }
}

private class QuickStartChecklistDataSource: NSObject, UITableViewDataSource {
    private var isChecklistCompleted: (Bool) -> Void
    private var blog: Blog
    private var completedTours = Set<String>()

    init(blog: Blog, _ isChecklistCompleted: @escaping (Bool) -> Void) {
        self.blog = blog
        self.isChecklistCompleted = isChecklistCompleted

        super.init()
        loadCompletedTours()
    }

    func loadCompletedTours() {
        guard let tours = blog.completedQuickStartTours else {
            return
        }

        completedTours = Set<String>()
        for tour in tours {
            completedTours.insert(tour.tourID)
        }

        isChecklistCompleted(completedTours.count == QuickStartTourGuide.checklistTours.count)
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
}
