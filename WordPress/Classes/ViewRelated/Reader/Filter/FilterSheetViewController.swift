import WordPressUI
import WordPressFlux

class FilterSheetViewController: UIViewController {

    // MARK: Properties

    private let viewTitle: String

    private let filterProvider: FilterProvider

    // closure that's called when a filter item is selected.
    private let changedFilter: (ReaderAbstractTopic) -> Void

    private var receipt: Receipt?

    private var dataSource: FilterTableViewDataSource? {
        didSet {
            tableView.dataSource = dataSource
            tableView.reloadData()
        }
    }

    // MARK: Views

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableFooterView = UIView() // To hide the separators for empty cells
        tableView.separatorStyle = .none
        tableView.delegate = self
        return tableView
    }()

    private lazy var emptyView = EmptyFilterView(
        viewModel: EmptyFilterViewModel(
            filterType: filterProvider.filterType,
            suggestedButtonTap: { [weak self] in
                self?.tappedSuggestedButton()
            }, searchButtonTap: { [weak self] in
                self?.tappedEmptyAddButton()
            }
        )
    )

    private lazy var ghostableTableView: UITableView = {
        let tableView = UITableView()
        tableView.allowsSelection = false
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        return tableView
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
            tableView,
            ghostableTableView,
            emptyView
        ])

        stack.setCustomSpacing(HeaderConstants.spacing, after: headerLabelView)
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: Methods

    init(filter: FilterProvider,
         viewTitle: String? = nil,
         changedFilter: @escaping (ReaderAbstractTopic) -> Void) {
        let defaultTitle = filter.section == .sites ? Strings.blogFilterTitle : Strings.tagFilterTitle
        self.viewTitle = viewTitle ?? defaultTitle
        self.filterProvider = filter
        self.changedFilter = changedFilter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViews()
        configureObservers()
        refresh()
    }
}

// MARK: - Private Helpers

private extension FilterSheetViewController {

    struct HeaderConstants {
        static let spacing: CGFloat = 16
        static let insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        static let font = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)
    }

    struct Strings {
        static let blogFilterTitle = NSLocalizedString(
            "reader.filterSheet.byBlog.title",
            value: "Filter by blog",
            comment: "Title for a filter sheet on the Reader to filter the stream by blog"
        )
        static let tagFilterTitle = NSLocalizedString(
            "reader.filterSheet.byTag.title",
            value: "Filter by tag",
            comment: "Title for a filter sheet on the Reader to filter the stream by tag"
        )
        static let selectInterestsTitle = NSLocalizedString(
            "reader.filterSheet.select.tags.title",
            value: "Suggested tags",
            comment: "Screen title. Reader select interests title label text."
        )
        static let selectInterestsLoading = NSLocalizedString(
            "reader.filterSheet.select.tags.loading",
            value: "Following new tags...",
            comment: "Label displayed to the user while loading their selected interests"
        )
    }

    func configureViews() {
        // configure table view
        tableView.register(filterProvider.cellClass, forCellReuseIdentifier: filterProvider.reuseIdentifier)

        // configure content view
        view.addSubview(stackView)
        view.pinSubviewToAllEdges(stackView)
    }

    func configureObservers() {
        receipt = filterProvider.onChange { [weak self] in
            guard let self else {
                return
            }

            self.dataSource = FilterTableViewDataSource(data: self.filterProvider.items,
                                                        reuseIdentifier: self.filterProvider.reuseIdentifier)
            if !self.filterProvider.state.isReady {
                /// Loading state
                self.emptyView.isHidden = true
                self.tableView.isHidden = true
                self.headerLabelView.isHidden = false
                self.updateGhostableTableViewOptions(cellClass: self.filterProvider.cellClass,
                                                     identifier: self.filterProvider.reuseIdentifier)
            } else {
                /// Finished loading
                self.ghostableTableView.stopGhostAnimation()
                self.ghostableTableView.isHidden = true

                let isEmpty = self.filterProvider.items.isEmpty
                self.emptyView.isHidden = !isEmpty
                self.tableView.isHidden = isEmpty
                self.headerLabelView.isHidden = isEmpty
            }
        }
    }

    func tappedSuggestedButton() {
        guard filterProvider.filterType == .tag else {
            assertionFailure("Unsupported suggested button action")
            return
        }
        let configuration = ReaderSelectInterestsConfiguration(
            title: Strings.selectInterestsTitle,
            subtitle: nil,
            buttonTitle: nil,
            loading: Strings.selectInterestsLoading
        )
        let controller = ReaderSelectInterestsViewController(configuration: configuration)

        controller.didSaveInterests = { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
            self?.refresh()
        }

        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .formSheet

        present(navController, animated: true, completion: nil)
    }

    func tappedEmptyAddButton() {
        switch filterProvider.filterType {
        case .blog:
            let searchController = ReaderSearchViewController.controller()
            searchController.onViewWillDisappear = { [weak self] in
                self?.refresh()
            }
            let navController = UINavigationController(rootViewController: searchController)
            navController.modalPresentationStyle = .formSheet
            present(navController, animated: true)
            break
        case .tag:
            filterProvider.showAdd(on: self, sceneDelegate: self)
        }
    }

    func refresh() {
        filterProvider.refresh()
    }

    func updateGhostableTableViewOptions(cellClass: UITableViewCell.Type, identifier: String) {
        ghostableTableView.register(cellClass, forCellReuseIdentifier: identifier)
        let ghostOptions = GhostOptions(displaysSectionHeader: false, reuseIdentifier: identifier, rowsPerSection: [15])
        let style = GhostStyle(beatDuration: GhostStyle.Defaults.beatDuration,
                               beatStartColor: .placeholderElement,
                               beatEndColor: .placeholderElementFaded)
        ghostableTableView.removeGhostContent()
        ghostableTableView.isHidden = false
        ghostableTableView.displayGhostContent(options: ghostOptions, style: style)
    }
}

// MARK: - UITableViewDelegate

extension FilterSheetViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let topic = dataSource?.data[indexPath.row].topic {
            changedFilter(topic)
        }
    }
}

// MARK: - SceneDelegate

extension FilterSheetViewController: ScenePresenterDelegate {
    func didDismiss(presenter: ScenePresenter) {
        refresh()
    }
}

// MARK: - DrawerPresentable

extension FilterSheetViewController: DrawerPresentable {
    func handleDismiss() {
        WPAnalytics.track(.readerFilterSheetDismissed)
    }

    var scrollableView: UIScrollView? {
        return tableView
    }

    var collapsedHeight: DrawerHeight {
        if traitCollection.verticalSizeClass == .compact {
            return .maxHeight
        } else {
            return .contentHeight(0)
        }
    }
}
