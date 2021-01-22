import Foundation

class JetpackScanCoordinator {
    private let service: JetpackScanService
    private let view: JetpackScanView

    private(set) var scan: JetpackScan?

    let blog: Blog

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

    public func viewDidLoad() {
        view.showLoading()

        refreshData()
    }

    public func refreshData() {
        service.getScan(for: blog) { [weak self] scanObj in
            self?.refreshDidSucceed(with: scanObj)
        } failure: { [weak self] error in
            DDLogError("Error fetching scan object: \(String(describing: error?.localizedDescription))")

            self?.view.showError()
        }
    }

    public func viewWillDisappear() {
        stopPolling()
    }

    private func refreshDidSucceed(with scanObj: JetpackScan) {
        scan = scanObj
        view.render()

        togglePolling()
    }

    public func startScan() {
        // Optimistically trigger the scanning state
        scan?.state = .scanning

        // Refresh the view's scan state
        view.render()

        // Since we've locally entered the scanning state, start polling
        // but don't trigger a refresh immediately after calling because the
        // server doesn't update its state immediately after starting a scan
        startPolling(triggerImmediately: false)

        service.startScan(for: blog) { [weak self] (success) in
            if success == false {
                DDLogError("Error starting scan: Scan response returned false")

                self?.view.showError()
            }
        } failure: { [weak self] (error) in
            DDLogError("Error starting scan: \(String(describing: error?.localizedDescription))")

            self?.view.showError()
        }
    }

    public func presentFixAllAlert() {
        let threatCount = scan?.fixableThreats?.count ?? 0

        let title: String
        let message: String

        if threatCount == 1 {
            title = Strings.fixAllSingleAlertTitle
            message = Strings.fixAllSingleAlertMessage
        } else {
            title = String(format: Strings.fixAllAlertTitleFormat, threatCount)
            message = Strings.fixAllAlertTitleMessage
        }

        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)

        controller.addAction(UIAlertAction(title: Strings.fixAllAlertCancelButtonTitle, style: .cancel, handler: nil))
        controller.addAction(UIAlertAction(title: Strings.fixAllAlertConfirmButtonTitle, style: .default, handler: { [weak self] _ in
            self?.fixAllThreats()
        }))

        view.presentAlert(controller)
    }

    public func fixAllThreats() {
        let fixableThreats = threats?.filter { $0.fixable != nil } ?? []

        // If there are no fixable threats just reload the state since it may be out of date
        guard fixableThreats.count > 0 else {
            refreshData()
            return
        }

        service.fixThreats(fixableThreats, blog: blog) {  [weak self] (response) in
            self?.refreshData()
        } failure: { [weak self] (error) in
            DDLogError("Error fixing threats: \(String(describing: error.localizedDescription))")

            self?.view.showError()
        }
    }

    public func ignoreThreat(threat: JetpackScanThreat) {

    }

    public func openSupport() {
        let supportVC = SupportTableViewController()
        supportVC.showFromTabBar()
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

    private func startPolling(triggerImmediately: Bool = true) {
        guard refreshTimer == nil else {
            return
        }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: Constants.refreshTimerInterval, repeats: true, block: { [weak self] (_) in
            self?.refreshData()
        })

        // Immediately trigger the refresh if needed
        guard triggerImmediately else {
            return
        }
        refreshData()
    }

    private struct Constants {
        static let refreshTimerInterval: TimeInterval = 5
    }

    private struct Strings {
        static let fixAllAlertTitleFormat = NSLocalizedString("Please confirm you want to fix all %1$d active threats", comment: "Confirmation title presented before fixing all the threats, displays the number of threats to be fixed")
        static let fixAllSingleAlertTitle = NSLocalizedString("Please confirm you want to fix this threat", comment: "Confirmation title presented before fixing a single threat")
        static let fixAllAlertTitleMessage = NSLocalizedString("Jetpack will be fixing all the detected active threats.", comment: "Confirmation message presented before fixing all the threats, displays the number of threats to be fixed")
        static let fixAllSingleAlertMessage = NSLocalizedString("Jetpack will be fixing the detected active threat.", comment: "Confirmation message presented before fixing a single threat")

        static let fixAllAlertCancelButtonTitle = NSLocalizedString("Cancel", comment: "Button title, cancel fixing all threats")
        static let fixAllAlertConfirmButtonTitle = NSLocalizedString("Fix all threats", comment: "Button title, confirm fixing all threats")
    }
}

protocol JetpackScanView {
    func render()

    func showLoading()
    func showError()

    func presentAlert(_ alert: UIAlertController)
}

extension JetpackScan {
    var hasFixableThreats: Bool {
        let count = fixableThreats?.count ?? 0
        return count > 0
    }

    var fixableThreats: [JetpackScanThreat]? {
        return threats?.filter { $0.fixable != nil }
    }
}
