import Foundation

class JetpackScanHistoryCoordinator {
    private let service: JetpackScanService
    private let view: JetpackScanHistoryView

    private(set) var model: JetpackScanHistory?

    let blog: Blog

    // Filtering
    var activeFilter: Filter = .all
    let filterItems = [Filter.all, .fixed, .ignored]

    private var actionButtonState: ErrorButtonAction?

    var threats: [JetpackScanThreat]? {
        guard let threats = model?.threats else {
            return nil
        }

        switch activeFilter {
            case .all:
                return threats
            case .fixed:
                return threats.filter { $0.status == .fixed }
            case .ignored:
                return threats.filter { $0.status == .ignored }
        }
    }

    init(blog: Blog,
         view: JetpackScanHistoryView,
         service: JetpackScanService? = nil,
         context: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {

        self.service = service ?? JetpackScanService(managedObjectContext: context)
        self.blog = blog
        self.view = view
    }

    // MARK: - Public Methods
    public func viewDidLoad() {
        view.showLoading()

        refreshData()
    }

    public func refreshData() {
        service.getHistory(for: blog) { [weak self] scanObj in
            self?.refreshDidSucceed(with: scanObj)
        } failure: { [weak self] error in
            DDLogError("Error fetching scan object: \(String(describing: error.localizedDescription))")
            self?.refreshDidFail(with: error)
        }
    }

    public func noResultsButtonPressed() {
        guard let action = actionButtonState else {
            return
        }

        switch action {
            case .contactSupport:
                openSupport()
            case .tryAgain:
                refreshData()
        }
    }

    private func openSupport() {
        let supportVC = SupportTableViewController()
        supportVC.showFromTabBar()
    }

    // MARK: - Private: Handling
    private func refreshDidSucceed(with model: JetpackScanHistory) {
        self.model = model

        threatsDidChange()
    }

    private func refreshDidFail(with error: Error? = nil) {
        let appDelegate = WordPressAppDelegate.shared

        guard
            let connectionAvailable = appDelegate?.connectionAvailable, connectionAvailable == true
        else {
            view.showNoConnectionError()
            actionButtonState = .tryAgain

            return
        }

        view.showGenericError()
        actionButtonState = .contactSupport
    }

    private func threatsDidChange() {
        guard let threatCount = threats?.count, threatCount > 0 else {
            switch activeFilter {
                case .all:
                    view.showNoHistory()
                case .fixed:
                    view.showNoFixedThreats()
                case .ignored:
                    view.showNoIgnoredThreats()
            }

            return
        }

        view.render()
    }

    // MARK: - Filters
    func changeFilter(_ filter: Filter) {
        activeFilter = filter

        threatsDidChange()
    }

    enum Filter: Int, FilterTabBarItem {
        case all = 0
        case fixed = 1
        case ignored = 2

        var title: String {
            switch self {
                case .all:
                    return NSLocalizedString("All", comment: "Displays all of the historical threats")
                case .fixed:
                    return NSLocalizedString("Fixed", comment: "Displays the fixed threats")
                case .ignored:
                    return NSLocalizedString("Ignored", comment: "Displays the ignored threats")
            }
        }

        var accessibilityIdentifier: String {
            switch self {
                case .all:
                    return NSLocalizedString("All", comment: "Displays all of the historical threats")
                case .fixed:
                    return NSLocalizedString("Fixed", comment: "Displays the fixed threats")
                case .ignored:
                    return NSLocalizedString("Ignored", comment: "Displays the ignored threats")
            }
        }
    }

    private enum ErrorButtonAction {
        case contactSupport
        case tryAgain
    }
}

protocol JetpackScanHistoryView {
    func render()

    func showLoading()

    // Errors
    func showNoHistory()
    func showNoFixedThreats()
    func showNoIgnoredThreats()
    func showNoConnectionError()
    func showGenericError()
}
