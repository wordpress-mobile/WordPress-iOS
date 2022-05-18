import Gridicons

class QuickStartChecklistViewController: UITableViewController {
    private var blog: Blog
    private var collection: QuickStartToursCollection
    private var observer: NSObjectProtocol?
    private var dataManager: QuickStartChecklistManager? {
        didSet {
            tableView?.dataSource = dataManager
            tableView?.delegate = dataManager
        }
    }

    private lazy var closeButtonItem: UIBarButtonItem = {
        let cancelButton = WPStyleGuide.buttonForBar(with: Constants.closeButtonModalImage, target: self, selector: #selector(closeWasPressed))
        cancelButton.leftSpacing = Constants.cancelButtonPadding.left
        cancelButton.rightSpacing = Constants.cancelButtonPadding.right
        cancelButton.setContentHuggingPriority(.required, for: .horizontal)

        let accessibleFormat = NSLocalizedString("Dismiss %@ Quick Start step", comment: "Accessibility description for the %@ step of Quick Start. Tapping this dismisses the checklist for that particular step.")
        cancelButton.accessibilityLabel = String(format: accessibleFormat, self.collection.title)

        return UIBarButtonItem(customView: cancelButton)
    }()

    init(blog: Blog, collection: QuickStartToursCollection) {
        self.blog = blog
        self.collection = collection
        super.init(style: .plain)
        startObservingForQuickStart()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()

        navigationItem.title = collection.title
        navigationItem.leftBarButtonItem = closeButtonItem

        dataManager = QuickStartChecklistManager(blog: blog,
                                                 tours: collection.tours,
                                                 didSelectTour: { [weak self] tour in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }

                WPAnalytics.trackQuickStartStat(.quickStartChecklistItemTapped,
                                                properties: ["task_name": tour.analyticsKey],
                                                blog: self.blog)

                QuickStartTourGuide.shared.prepare(tour: tour, for: self.blog)

                self.dismiss(animated: true) {
                    QuickStartTourGuide.shared.begin()
                }
            }
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // should display bg and trigger qs notification

        WPAnalytics.trackQuickStartStat(.quickStartChecklistViewed,
                                        properties: [Constants.analyticsTypeKey: collection.analyticsKey],
                                        blog: blog)
    }
}

private extension QuickStartChecklistViewController {
    func configureTableView() {
        let tableView = UITableView(frame: .zero)

        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.separatorStyle = .none
        tableView.cellLayoutMarginsFollowReadableWidth = true

        let cellNib = UINib(nibName: "QuickStartChecklistCell", bundle: Bundle(for: QuickStartChecklistCell.self))
        tableView.register(cellNib, forCellReuseIdentifier: QuickStartChecklistCell.reuseIdentifier)

        self.tableView = tableView
        WPStyleGuide.configureTableViewColors(view: self.tableView)
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

    @objc private func closeWasPressed(sender: UIButton) {
        WPAnalytics.trackQuickStartStat(.quickStartTypeDismissed,
                                        properties: [Constants.analyticsTypeKey: collection.analyticsKey],
                                        blog: blog)
        dismiss(animated: true, completion: nil)
    }
}

private struct TasksCompleteScreenConfiguration {
    var title: String
    var subtitle: String
    var imageName: String
}

private struct QuickStartChecklistConfiguration {
    var title: String
    var tours: [QuickStartTour]
}

private enum Constants {
    static let analyticsTypeKey = "type"
    static let cancelButtonPadding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
    static let closeButtonModalImage = UIImage.gridicon(.cross)
    static let estimatedRowHeight: CGFloat = 90.0
}
