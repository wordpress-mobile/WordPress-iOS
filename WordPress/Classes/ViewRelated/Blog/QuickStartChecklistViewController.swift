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

        configureTableView()

        guard let blog = blog, let configuration = configuration else {
            return
        }

        navigationItem.title = configuration.title

        dataManager = QuickStartChecklistManager(blog: blog, tours: configuration.list, didSelectTour: { [weak self] analyticsKey in
            DispatchQueue.main.async {
                WPAnalytics.track(.quickStartChecklistItemTapped, withProperties: ["task_name": analyticsKey])
                self?.navigationController?.popViewController(animated: true)
            }
        }, didTapHeader: { collapse in
            // display/hide congratulation screen
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // should display bg and trigger qs notification

        WPAnalytics.track(.quickStartChecklistViewed)
    }
}

private extension QuickStartChecklistViewController {
    func configureTableView() {
        let tableView = UITableView(frame: .zero)

        if #available(iOS 10, *) {
            tableView.estimatedRowHeight = 90.0
        }
        tableView.separatorStyle = .none

        let cellNib = UINib(nibName: "QuickStartChecklistCell", bundle: Bundle(for: QuickStartChecklistCell.self))
        tableView.register(cellNib, forCellReuseIdentifier: QuickStartChecklistCell.reuseIdentifier)

        self.tableView = tableView
    }

    func startObservingForQuickStart() {
        observer = NotificationCenter.default.addObserver(forName: .QuickStartTourElementChangedNotification, object: nil, queue: nil) { [weak self] (notification) in
            guard let userInfo = notification.userInfo,
                let element = userInfo[QuickStartTourGuide.notificationElementKey] as? QuickStartTourElement,
                element == .tourCompleted else {
                    return
            }
            self?.reload()
        }
    }

    func reload() {
        dataManager?.reloadData()
        tableView.reloadData()
    }
}
