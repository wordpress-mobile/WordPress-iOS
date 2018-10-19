class QuickStartChecklistViewController: UITableViewController {
    private var dataSource: QuickStartChecklistDataSource? {
        didSet {
            self.tableView?.dataSource = dataSource
        }
    }
    private var blog: Blog?
    private var observer: NSObjectProtocol?

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
        let completedCellNib = UINib(nibName: "QuickStartChecklistCompletedCell", bundle: Bundle(for: QuickStartChecklistCompletedCell.self))
        tableView.register(completedCellNib, forCellReuseIdentifier: QuickStartChecklistCompletedCell.reuseIdentifier)

        guard let blog = blog else {
            return
        }
        dataSource = QuickStartChecklistDataSource(blog: blog)
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
}

private class QuickStartChecklistDataSource: NSObject, UITableViewDataSource {
    private var blog: Blog
    private var completedTours = Set<String>()

    init(blog: Blog) {
        self.blog = blog

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
    }

    // managing tours

    func tour(at indexPath: IndexPath) -> QuickStartTour {
        return QuickStartTourGuide.checklistTours[indexPath.row]
    }

    func isCompleted(tour: QuickStartTour) -> Bool {
        return completedTours.contains(tour.key)
    }

    func shouldShowCongratulations() -> Bool {
        let completedToursCount = blog.completedQuickStartTours?.count ?? 0
        return completedToursCount >= completedTours.count
    }

    // UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let congratulationsCount = shouldShowCongratulations() ? 1 : 0
        return QuickStartTourGuide.checklistTours.count + congratulationsCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row > 0 else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: QuickStartChecklistCompletedCell.reuseIdentifier) as? QuickStartChecklistCompletedCell {
                return cell
            }
            return UITableViewCell()
        }
        if let cell = tableView.dequeueReusableCell(withIdentifier: QuickStartChecklistCell.reuseIdentifier) as? QuickStartChecklistCell {
            let tour = QuickStartTourGuide.checklistTours[indexPath.row - 1]
            cell.tour = tour
            if isCompleted(tour: tour) {
                cell.completed = true
            }
            return cell
        }
        return UITableViewCell()
    }
}
