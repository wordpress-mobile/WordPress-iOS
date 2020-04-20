import WordPressFlux

class FilterSheetView: UIView {

    enum Constants {
        enum Header {
            static let spacing: CGFloat = 16
            static let insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
            static let title = NSLocalizedString("Following", comment: "Title for Reader Filter Sheet")
            static let font = WPStyleGuide.fontForTextStyle(.headline)
        }
    }

    // MARK: View Setup

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableFooterView = UIView() // To hide the separators for empty cells
        tableView.separatorStyle = .none
        tableView.delegate = self
        return tableView
    }()

    lazy var ghostableTableView: UITableView = {
        let tableView = UITableView()
        tableView.allowsSelection = false
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        return tableView
    }()

    lazy var filterTabBar: FilterTabBar = {
        let tabBar = FilterTabBar()
        WPStyleGuide.configureFilterTabBar(tabBar)
        tabBar.tabSizingStyle = .equalWidths
        tabBar.addTarget(self, action: #selector(FilterSheetView.changedTab(_:)), for: .valueChanged)
        return tabBar
    }()

    lazy var headerLabelView: UIView = {
        let labelView = UIView()
        let label = UILabel()
        label.font = Constants.Header.font
        label.text = Constants.Header.title
        label.translatesAutoresizingMaskIntoConstraints = false
        labelView.addSubview(label)
        labelView.pinSubviewToAllEdges(label, insets: Constants.Header.insets)
        return labelView
    }()

    lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            headerLabelView,
            filterTabBar,
            tableView,
            ghostableTableView
        ])

        stack.setCustomSpacing(Constants.Header.spacing, after: headerLabelView)
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: Properties

    private var subscriptions: [Receipt]?
    private var changedFilter: (ReaderAbstractTopic) -> Void
    private var dataSource: FilterTableViewDataSource? {
        didSet {
            tableView.dataSource = dataSource
            tableView.reloadData()
        }
    }

    private var selectedFilter: FilterProvider? {
        set {
            if let filter = newValue {
                dataSource = FilterTableViewDataSource(data: filter.items, reuseIdentifier: filter.reuseIdentifier)
                if filter.state.isReady == false {
                    tableView.isHidden = true
                    updateGhostableTableViewOptions(cellClass: filter.cellClass, identifier: filter.reuseIdentifier)
                } else {
                    ghostableTableView.stopGhostAnimation()
                    ghostableTableView.isHidden = true
                    tableView.isHidden = false
                }
            }
        }
        get {
            return filterTabBar.items[filterTabBar.selectedIndex] as? FilterProvider
        }
    }

    // MARK: Methods

    init(filters: [FilterProvider], changedFilter: @escaping (ReaderAbstractTopic) -> Void) {
        self.changedFilter = changedFilter
        super.init(frame: .zero)

        filterTabBar.items = filters
        filters.forEach { filter in
            tableView.register(filter.cellClass, forCellReuseIdentifier: filter.reuseIdentifier)
        }
        selectedFilter = filters.first

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
}

extension FilterSheetView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let topic = dataSource?.data[indexPath.row].topic {
            changedFilter(topic)
        }
    }
}
