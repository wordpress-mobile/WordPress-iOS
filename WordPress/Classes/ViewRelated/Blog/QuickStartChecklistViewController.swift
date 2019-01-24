struct TasksCompleteScreenConfiguration {
    var title: String
    var subtitle: String
    var imageName: String
}

struct QuickStartChecklistConfiguration {
    var title: String?
    var list: [QuickStartTour]
    var tasksCompleteScreen: TasksCompleteScreenConfiguration?

    init(title: String? = nil, list: [QuickStartTour], tasksCompleteScreen: TasksCompleteScreenConfiguration? = nil) {
        self.title = title
        self.list = list
        self.tasksCompleteScreen = tasksCompleteScreen
    }
}

class QuickStartChecklistViewController: UITableViewController {
    private var dataSource: QuickStartChecklistDataSource? {
        didSet {
            self.tableView?.dataSource = dataSource
        }
    }
    private var dataManager: QuickStartChecklistManager? {
        didSet {
            tableView?.dataSource = dataManager
            tableView?.delegate = dataManager
        }
    }
    private var blog: Blog?
    private var configuration: QuickStartChecklistConfiguration?
    private var observer: NSObjectProtocol?

    @objc convenience init(blog: Blog) {
        self.init(blog: blog, configuration: QuickStartChecklistConfiguration(list: QuickStartTourGuide.checklistTours))
    }

    convenience init(blog: Blog, configuration: QuickStartChecklistConfiguration) {
        self.init()
        self.blog = blog
        self.configuration = configuration

        startObservingForQuickStart()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tableView = UITableView(frame: .zero)

        let quickStartV2Enabled = Feature.enabled(.quickStartV2)

        if quickStartV2Enabled {
            if #available(iOS 10, *) {
                tableView.estimatedRowHeight = 90.0
            }
            tableView.tableFooterView = UIView(frame: .zero)
        } else {
            if #available(iOS 11, *) {
                tableView.estimatedRowHeight = UITableView.automaticDimension
            } else {
                tableView.estimatedRowHeight = WPTableViewDefaultRowHeight
            }

            register(QuickStartCongratulationsCell.self, tableView: tableView, reuseIdentifier: QuickStartCongratulationsCell.reuseIdentifier)
            register(QuickStartSkipAllCell.self, tableView: tableView, reuseIdentifier: QuickStartSkipAllCell.reuseIdentifier)
        }

        let nibName = quickStartV2Enabled ? "QuickStartChecklistCellV2" : "QuickStartChecklistCell"
        register(QuickStartChecklistCell.self, tableView: tableView, nibName: nibName, reuseIdentifier: QuickStartChecklistCell.reuseIdentifier)

        self.tableView = tableView

        guard let blog = blog, let configuration = configuration else {
            return
        }

        navigationItem.title = configuration.title

        if quickStartV2Enabled {
            dataManager = QuickStartChecklistManager(blog: blog, tours: configuration.list, didSelectTour: { [weak self] analyticsKey in
                DispatchQueue.main.async {
                    self?.popViewController(analyticsKey: analyticsKey)
                }
            }, didTapHeader: { collapse in
                // display/hide congratulation screen
            })
        } else {
            dataSource = QuickStartChecklistDataSource(blog: blog, tours: configuration.list)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if Feature.enabled(.quickStartV2) {
            // should display bg and trigger qs notification
        } else {
            if dataSource?.shouldShowCongratulations() ?? false {
                if let blog = blog {
                    QuickStartTourGuide.find()?.complete(tour: QuickStartCongratulationsTour(), for: blog)
                }
            }
        }

        WPAnalytics.track(.quickStartChecklistViewed)
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let section = Sections(rawValue: indexPath.section) {
            switch section {
            case .congratulations:
                return nil
            case .checklistItems:
                guard let tour = dataSource?.tour(at: indexPath),
                    !(tour is QuickStartCreateTour) else {
                        return nil
                }
            case .skipAll:
                guard let blog = blog else {
                    return nil
                }
                QuickStartTourGuide.find()?.skipAll(for: blog) { [weak self] in
                    self?.reload()
                    self?.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                }
                return nil
            }
        }
        return indexPath
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tourGuide = QuickStartTourGuide.find(),
            Sections(rawValue: indexPath.section) == .checklistItems,
            let blog = blog,
            let tour = dataSource?.tour(at: indexPath) else {
                return
        }
        tourGuide.start(tour: tour, for: blog)
        popViewController(analyticsKey: tour.analyticsKey)
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

            self?.reload()
        }
    }

    private func reload() {
        if Feature.enabled(.quickStartV2) {
            dataManager?.reloadData()
        } else {
            dataSource?.loadCompletedTours()
        }
        tableView.reloadData()
    }

    private func popViewController(analyticsKey: String) {
        WPAnalytics.track(.quickStartChecklistItemTapped, withProperties: ["task_name": analyticsKey])
        navigationController?.popViewController(animated: true)
    }

    private func register<T: AnyObject>(_ item: T.Type, tableView: UITableView, nibName: String? = nil, reuseIdentifier: String) {
        let congratulationsNib = UINib(nibName: nibName ?? String(describing: T.self), bundle: Bundle(for: T.self))
        tableView.register(congratulationsNib, forCellReuseIdentifier: reuseIdentifier)
    }
}

private class QuickStartChecklistDataSource: NSObject, UITableViewDataSource {
    private var blog: Blog
    private var tours: [QuickStartTour]
    private var completedTours = Set<String>()

    init(blog: Blog, tours: [QuickStartTour]) {
        self.blog = blog
        self.tours = tours

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
        return tours[indexPath.row]
    }

    func isCompleted(tour: QuickStartTour) -> Bool {
        return completedTours.contains(tour.key)
    }

    func shouldShowCongratulations() -> Bool {
        // TODO: fix this count implementation to be compatible with v2
        let completedToursCount = QuickStartTourGuide.countChecklistCompleted(for: blog)
        return completedToursCount >= tours.count
    }

    // UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Sections(rawValue: section) else {
            return 0
        }

        switch section {
        case .congratulations:
            if shouldShowCongratulations() {
                return 1
            } else {
                return 0
            }
        case .checklistItems:
            return tours.count
        case .skipAll:
            return shouldShowCongratulations() ? 0 : 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let section = Sections(rawValue: indexPath.section) {
            switch section {
            case .congratulations:
                if let cell = tableView.dequeueReusableCell(withIdentifier: QuickStartCongratulationsCell.reuseIdentifier) as? QuickStartCongratulationsCell {
                    return cell
                }
            case .checklistItems:
                if let cell = tableView.dequeueReusableCell(withIdentifier: QuickStartChecklistCell.reuseIdentifier) as? QuickStartChecklistCell {
                    let tour = tours[indexPath.row]
                    cell.tour = tour
                    cell.completed = isCompleted(tour: tour)
                    return cell
                }
            case .skipAll:
                if let cell = tableView.dequeueReusableCell(withIdentifier: QuickStartSkipAllCell.reuseIdentifier) as? QuickStartSkipAllCell {
                    return cell
                }
            }
        }
        return UITableViewCell()
    }
}

private enum Sections: Int {
    case congratulations = 0
    case checklistItems = 1
    case skipAll = 2
}
