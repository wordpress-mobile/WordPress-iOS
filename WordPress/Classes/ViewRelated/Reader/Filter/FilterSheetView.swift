import WordPressFlux

class FilterSheetView: UIView {

    private struct HeaderConstants {
        static let spacing: CGFloat = 16
        static let insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        static let font = WPStyleGuide.fontForTextStyle(.headline)
    }

    // MARK: View Setup

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableFooterView = UIView() // To hide the separators for empty cells
        tableView.separatorStyle = .none
        tableView.delegate = self
        return tableView
    }()

    private lazy var emptyView: EmptyActionView = {
        let view = EmptyActionView(tappedButton: tappedEmptyAddButton)

        // Hide the button if the user is not logged in
        view.button.isHidden = !ReaderHelpers.isLoggedIn()

        return view
    }()

    private lazy var ghostableTableView: UITableView = {
        let tableView = UITableView()
        tableView.allowsSelection = false
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        return tableView
    }()

    private lazy var filterTabBar: FilterTabBar = {
        let tabBar = FilterTabBar()
        WPStyleGuide.configureFilterTabBar(tabBar)
        tabBar.tabSizingStyle = .equalWidths
        tabBar.addTarget(self, action: #selector(FilterSheetView.changedTab(_:)), for: .valueChanged)
        return tabBar
    }()

    private lazy var headerLabelView: UIView = {
        let labelView = UIView()
        let label = UILabel()
        label.font = HeaderConstants.font
        label.text = viewTitle
        label.translatesAutoresizingMaskIntoConstraints = false
        labelView.addSubview(label)
        labelView.pinSubviewToAllEdges(label, insets: HeaderConstants.insets)
        return labelView
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            headerLabelView,
            filterTabBar,
            tableView,
            ghostableTableView,
            emptyView
        ])

        stack.setCustomSpacing(HeaderConstants.spacing, after: headerLabelView)
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: Properties

    private weak var presentationController: UIViewController?
    private var subscriptions: [Receipt]?
    private var changedFilter: (ReaderAbstractTopic) -> Void
    private var dataSource: FilterTableViewDataSource? {
        didSet {
            tableView.dataSource = dataSource
            tableView.reloadData()
        }
    }

    private func tappedEmptyAddButton() {
        if let controller = presentationController {
            selectedFilter?.showAdd(on: controller, sceneDelegate: self)
        }
    }

    private var selectedFilter: FilterProvider? {
        set {
            if let filter = newValue {
                dataSource = FilterTableViewDataSource(data: filter.items, reuseIdentifier: filter.reuseIdentifier)
                if !filter.state.isReady {
                    /// Loading state
                    emptyView.isHidden = true
                    tableView.isHidden = true
                    updateGhostableTableViewOptions(cellClass: filter.cellClass, identifier: filter.reuseIdentifier)
                } else {
                    /// Finished loading
                    ghostableTableView.stopGhostAnimation()
                    ghostableTableView.isHidden = true

                    let isEmpty = filter.items.isEmpty
                    if isEmpty {
                        refreshEmpty(filter: filter)
                    }
                    emptyView.isHidden = !isEmpty
                    tableView.isHidden = isEmpty
                }
            }
        }
        get {
            return filterTabBar.items[filterTabBar.selectedIndex] as? FilterProvider
        }
    }

    private let viewTitle: String
    private let filters: [FilterProvider]

    // MARK: Methods

    init(viewTitle: String,
         filters: [FilterProvider],
         presentationController: UIViewController,
         changedFilter: @escaping (ReaderAbstractTopic) -> Void) {
        self.viewTitle = viewTitle
        self.filters = filters
        self.presentationController = presentationController
        self.changedFilter = changedFilter

        super.init(frame: .zero)

        filterTabBar.items = filters
        filters.forEach { filter in
            tableView.register(filter.cellClass, forCellReuseIdentifier: filter.reuseIdentifier)
        }
        selectedFilter = filters.first

        // If there is only one filter, don't show the filter tab bar.
        filterTabBar.isHidden = filters.count == 1

        addSubview(stackView)
        pinSubviewToAllEdges(stackView)

        subscriptions = filters.map() { filter in
            filter.onChange() { [weak self] in
                if self?.selectedFilter?.accessibilityIdentifier == filter.accessibilityIdentifier {
                    self?.selectedFilter = filter
                }
                self?.filterTabBar.items = filters
            }
        }

        refresh(filters: filters)
    }

    private func refresh(filters: [FilterProvider]) {
        filters.forEach({ provider in
            provider.refresh()
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateGhostableTableViewOptions(cellClass: UITableViewCell.Type, identifier: String) {
        ghostableTableView.register(cellClass, forCellReuseIdentifier: identifier)
        let ghostOptions = GhostOptions(displaysSectionHeader: false, reuseIdentifier: identifier, rowsPerSection: [15])
        let style = GhostStyle(beatDuration: GhostStyle.Defaults.beatDuration,
                               beatStartColor: .placeholderElement,
                               beatEndColor: .placeholderElementFaded)
        ghostableTableView.removeGhostContent()
        ghostableTableView.isHidden = false
        ghostableTableView.displayGhostContent(options: ghostOptions, style: style)
    }

    @objc func changedTab(_ sender: FilterTabBar) {
        selectedFilter = filterTabBar.items[sender.selectedIndex] as? FilterProvider
    }

    private func refreshEmpty(filter: FilterProvider) {
        emptyView.title = filter.emptyTitle
        emptyView.labelText = filter.emptyActionTitle
    }
}

extension FilterSheetView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let topic = dataSource?.data[indexPath.row].topic {
            changedFilter(topic)
        }
    }
}

extension FilterSheetView: ScenePresenterDelegate {
    func didDismiss(presenter: ScenePresenter) {
        refresh(filters: filters)
    }
}
