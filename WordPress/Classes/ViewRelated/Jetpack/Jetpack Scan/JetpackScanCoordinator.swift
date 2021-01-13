import Foundation

protocol JetpackScanView {
    func render(_ scan: JetpackScan)

    func showLoading()
    func showError()
}

class JetpackScanCoordinator {
    private let service: JetpackScanService
    private let blog: Blog
    private let view: JetpackScanView

    private(set) var scan: JetpackScan?

    /// Returns the threats if we're in the idle state
    var threats: [JetpackScanThreat]? {
        return scan?.state == .idle ? scan?.threats : nil
    }

    init(blog: Blog,
         view: JetpackScanView,
         service: JetpackScanService? = nil,
         context: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {

        self.service = service ?? JetpackScanService(managedObjectContext: context)
        self.blog = blog
        self.view = view
    }

    public func refreshData(showLoading: Bool = false) {
        if showLoading {
            view.showLoading()
        }

        service.getScan(for: blog) { [weak self] scanObj in
            self?.refreshDidSucceed(with: scanObj)
        } failure: { [weak self] error in
            DDLogError("Error fetching scan object: \(String(describing: error.localizedDescription))")

            self?.view.showError()
        }
    }

    private func refreshDidSucceed(with scanObj: JetpackScan) {
        scan = scanObj
        view.render(scanObj)

        togglePolling()
    }

    public func startScan() {
        service.startScan(for: blog) { (success) in

        } failure: { [weak self] (error) in
            DDLogError("Error starting scan: \(String(describing: error.localizedDescription))")

            self?.view.showError()
        }
    }

    public func fixThreats() {

    }

    public func ignoreThreat(threat: JetpackScanThreat) {

    }

    // MARK: - Private: Refresh Timer
    private var refreshTimer: Timer?

    /// Starts or stops the refresh timer based on the status of the scan
    private func togglePolling() {
        switch scan?.state {
        case .provisioning, .scanning:
            startPolling()
        default:
            stopPolling()
        }
    }

    private func stopPolling() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func startPolling() {
        guard refreshTimer == nil else {
            return
        }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: Constants.refreshTimerInterval, repeats: true, block: { [weak self] (_) in
            self?.refreshData()
        })

        // Immediately trigger the refresh
        refreshData()
    }

    private struct Constants {
        static let refreshTimerInterval: TimeInterval = 5
    }
}
