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
        let closeButton = UIButton()

        let configuration = UIImage.SymbolConfiguration(pointSize: Constants.closeButtonSymbolSize, weight: .bold)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: configuration), for: .normal)
        closeButton.tintColor = .secondaryLabel
        closeButton.backgroundColor = .quaternarySystemFill

        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: Constants.closeButtonRadius),
            closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor)
        ])
        closeButton.layer.cornerRadius = Constants.closeButtonRadius * 0.5

        let accessibleFormat = NSLocalizedString("Dismiss %@ Quick Start step", comment: "Accessibility description for the %@ step of Quick Start. Tapping this dismisses the checklist for that particular step.")
        closeButton.accessibilityLabel = String(format: accessibleFormat, self.collection.title)

        closeButton.addTarget(self, action: #selector(closeWasPressed), for: .touchUpInside)

        return UIBarButtonItem(customView: closeButton)
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
        configureNavigationBar()

        dataManager = QuickStartChecklistManager(blog: blog,
                                                 tours: collection.tours,
                                                 title: collection.shortTitle,
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

        tableView.flashScrollIndicators()

        WPAnalytics.trackQuickStartStat(.quickStartChecklistViewed,
                                        properties: [Constants.analyticsTypeKey: collection.analyticsKey],
                                        blog: blog)
    }
}

private extension QuickStartChecklistViewController {
    func configureTableView() {
        let tableView = UITableView(frame: .zero, style: .grouped)

        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.separatorStyle = .none
        tableView.cellLayoutMarginsFollowReadableWidth = true

        let cellNib = UINib(nibName: "QuickStartChecklistCell", bundle: Bundle(for: QuickStartChecklistCell.self))
        tableView.register(cellNib, forCellReuseIdentifier: QuickStartChecklistCell.reuseIdentifier)
        tableView.register(QuickStartChecklistHeader.defaultNib, forHeaderFooterViewReuseIdentifier: QuickStartChecklistHeader.defaultReuseID)
        self.tableView = tableView
        WPStyleGuide.configureTableViewColors(view: self.tableView)
    }

    func configureNavigationBar() {
        navigationItem.rightBarButtonItem = closeButtonItem

        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        navigationItem.standardAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactScrollEdgeAppearance = appearance
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

private enum Constants {
    static let analyticsTypeKey = "type"
    static let closeButtonRadius: CGFloat = 30
    static let closeButtonSymbolSize: CGFloat = 16
    static let estimatedRowHeight: CGFloat = 90.0
}
