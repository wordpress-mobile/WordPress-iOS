import Foundation

class JetpackScanHistoryCoordinator {
    private let service: JetpackScanService
    private let view: JetpackScanHistoryView

    private(set) var model: JetpackScanHistory?

    let blog: Blog

    // Filtering
    var activeFilter: Filter = .all
    let filterItems = [Filter.all, .fixed, .ignored]

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

    public func viewDidLoad() {
        view.showLoading()

        refreshData()
    }

    public func refreshData() {
        service.getHistory(for: blog) { [weak self] scanObj in
            self?.refreshDidSucceed(with: scanObj)
        } failure: { [weak self] error in
            DDLogError("Error fetching scan object: \(String(describing: error?.localizedDescription))")

            self?.view.showError()
        }
    }

    private func refreshDidSucceed(with model: JetpackScanHistory) {
        self.model = model
        view.render()
    }

    // MARK: - Filters
    func changeFilter(_ filter: Filter) {
        activeFilter = filter
        view.render()
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

}

protocol JetpackScanHistoryView {
    func render()

    func showLoading()
    func showError()

    func presentAlert(_ alert: UIAlertController)
}
