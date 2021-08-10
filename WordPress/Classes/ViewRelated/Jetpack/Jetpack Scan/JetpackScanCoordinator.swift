import Foundation

protocol JetpackScanView {
    func render()

    func showLoading()
    func showNoConnectionError()
    func showGenericError()
    func showScanStartError()
    func showMultisiteNotSupportedError()

    func toggleHistoryButton(_ isEnabled: Bool)

    func presentAlert(_ alert: UIAlertController)
    func presentNotice(with title: String, message: String?)

    func showIgnoreThreatSuccess(for threat: JetpackScanThreat)
    func showIgnoreThreatError(for threat: JetpackScanThreat)

    func showJetpackSettings(with siteID: Int)
}

class JetpackScanCoordinator {
    private let service: JetpackScanService
    private let view: JetpackScanView

    private(set) var scan: JetpackScan? {
        didSet {
            configureSections()
            scanDidChange(from: oldValue, to: scan)
        }
    }

    var hasValidCredentials: Bool {
        return scan?.hasValidCredentials ?? false
    }

    let blog: Blog

    /// Returns the threats if we're in the idle state
    var threats: [JetpackScanThreat]? {
        let returnThreats: [JetpackScanThreat]?

        if scan?.state == .fixingThreats {
            returnThreats = scan?.threatFixStatus?.compactMap { $0.threat } ?? nil
        } else {
            returnThreats = scan?.state == .idle ? scan?.threats : nil
        }

        // Sort the threats by date then by threat ID
        return returnThreats?.sorted(by: {
            if $0.firstDetected != $1.firstDetected {
                return $0.firstDetected > $1.firstDetected
            }

            return $0.id > $1.id
        })
    }

    var sections: [JetpackThreatSection]?

    private var actionButtonState: ErrorButtonAction?

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
        service.getScanWithFixableThreatsStatus(for: blog) { [weak self] scanObj in
            self?.refreshDidSucceed(with: scanObj)

        } failure: { [weak self] error in
            DDLogError("Error fetching scan object: \(String(describing: error?.localizedDescription))")

            self?.refreshDidFail(with: error)
        }
    }

    public func viewWillDisappear() {
        stopPolling()
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

                WPAnalytics.track(.jetpackScanError, properties: ["action": "scan",
                                                                  "cause": "scan response returned false"])

                self?.stopPolling()
                self?.view.showScanStartError()
            }
        } failure: { [weak self] (error) in
            DDLogError("Error starting scan: \(String(describing: error?.localizedDescription))")

            WPAnalytics.track(.jetpackScanError, properties: ["action": "scan",
                                                              "cause": error?.localizedDescription ?? "remote"])

            self?.refreshDidFail(with: error)
        }
    }

    // MARK: - Public Actions
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
            WPAnalytics.track(.jetpackScanAllthreatsFixTapped, properties: ["threats_fixed": threatCount])

            self?.fixAllThreats()
        }))

        view.presentAlert(controller)
    }

    private func fixThreats(threats: [JetpackScanThreat]) {
        // If there are no fixable threats just reload the state since it may be out of date
        guard threats.count > 0 else {
            refreshData()
            return
        }

        // Optimistically trigger the fixing state
        // and map all the fixable threats to in progress threats
        scan?.state = .fixingThreats
        scan?.threatFixStatus = threats.compactMap {
            var threatCopy = $0
            threatCopy.status = .fixing
            return JetpackThreatFixStatus(with: threatCopy)
        }

        // Refresh the view to show the new scan state
        view.render()

        startPolling(triggerImmediately: false)

        service.fixThreats(threats, blog: blog) { [weak self] (response) in
            if response.success == false {
                DDLogError("Error starting scan: Scan response returned false")
                self?.stopPolling()
                self?.view.showScanStartError()
            } else {
                self?.refreshData()
            }
        } failure: { [weak self] (error) in
            DDLogError("Error fixing threats: \(String(describing: error.localizedDescription))")

            self?.refreshDidFail(with: error)
        }
    }

    public func fixAllThreats() {
        let fixableThreats = threats?.filter { $0.fixable != nil } ?? []
        fixThreats(threats: fixableThreats)
    }

    public func fixThreat(threat: JetpackScanThreat) {
        fixThreats(threats: [threat])
    }

    public func ignoreThreat(threat: JetpackScanThreat) {
        service.ignoreThreat(threat, blog: blog, success: { [weak self] in
            self?.view.showIgnoreThreatSuccess(for: threat)
        }, failure: { [weak self] error in
            DDLogError("Error ignoring threat: \(error.localizedDescription)")

            WPAnalytics.track(.jetpackScanError, properties: ["action": "ignore",
                                                              "cause": error.localizedDescription])

            self?.view.showIgnoreThreatError(for: threat)
        })
    }

    public func openSupport() {
        let supportVC = SupportTableViewController()
        supportVC.showFromTabBar()
    }

    public func openJetpackSettings() {
        guard let siteID = blog.dotComID as? Int else {
            view.presentNotice(with: Strings.jetpackSettingsNotice.title, message: nil)
            return
        }
        view.showJetpackSettings(with: siteID)
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

    private func configureSections() {
        guard let threats = self.threats, let siteRef = JetpackSiteRef(blog: self.blog) else {
            sections = nil
            return
        }

        guard scan?.state == .fixingThreats else {
            sections = JetpackScanThreatSectionGrouping(threats: threats, siteRef: siteRef).sections

            return
        }

        sections = [JetpackThreatSection(title: nil, date: Date(), threats: threats)]
    }

    // MARK: - Private: Network Handlers
    private func refreshDidSucceed(with scanObj: JetpackScan) {
        scan = scanObj

        switch (scanObj.state, scanObj.reason) {
        case (.unavailable, JetpackScan.Reason.multiSiteNotSupported):
            view.showMultisiteNotSupportedError()
        default:
            view.render()
        }

        view.toggleHistoryButton(scan?.isEnabled ?? false)

        togglePolling()
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

    private func scanDidChange(from: JetpackScan?, to: JetpackScan?) {
        let fromState = from?.state ?? .unknown
        let toState = to?.state ?? .unknown

        // Trigger scan finished alert
        guard fromState == .scanning, toState == .idle else {
            return
        }

        let threatCount = threats?.count ?? 0

        let message: String

        switch threatCount {
            case 0:
                message = Strings.scanNotice.message

            case 1:
                message = Strings.scanNotice.messageSingleThreatFound

            default:
                message = String(format: Strings.scanNotice.messageThreatsFound, threatCount)
        }

        view.presentNotice(with: Strings.scanNotice.title, message: message)
    }

    // MARK: - Private: Refresh Timer
    private var refreshTimer: Timer?

    /// Starts or stops the refresh timer based on the status of the scan
    private func togglePolling() {
        switch scan?.state {
        case .provisioning, .scanning, .fixingThreats:
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
        struct scanNotice {
            static let title = NSLocalizedString("Scan Finished", comment: "Title for a notice informing the user their scan has completed")
            static let message = NSLocalizedString("No threats found", comment: "Message for a notice informing the user their scan completed and no threats were found")
            static let messageThreatsFound = NSLocalizedString("%d potential threats found", comment: "Message for a notice informing the user their scan completed and %d threats were found")
            static let messageSingleThreatFound = NSLocalizedString("1 potential threat found", comment: "Message for a notice informing the user their scan completed and 1 threat was found")
        }

        struct jetpackSettingsNotice {
            static let title = NSLocalizedString("Unable to visit Jetpack settings for site", comment: "Message displayed when visiting the Jetpack settings page fails.")
        }

        static let fixAllAlertTitleFormat = NSLocalizedString("Please confirm you want to fix all %1$d active threats", comment: "Confirmation title presented before fixing all the threats, displays the number of threats to be fixed")
        static let fixAllSingleAlertTitle = NSLocalizedString("Please confirm you want to fix this threat", comment: "Confirmation title presented before fixing a single threat")
        static let fixAllAlertTitleMessage = NSLocalizedString("Jetpack will be fixing all the detected active threats.", comment: "Confirmation message presented before fixing all the threats, displays the number of threats to be fixed")
        static let fixAllSingleAlertMessage = NSLocalizedString("Jetpack will be fixing the detected active threat.", comment: "Confirmation message presented before fixing a single threat")

        static let fixAllAlertCancelButtonTitle = NSLocalizedString("Cancel", comment: "Button title, cancel fixing all threats")
        static let fixAllAlertConfirmButtonTitle = NSLocalizedString("Fix all threats", comment: "Button title, confirm fixing all threats")
    }

    private enum ErrorButtonAction {
        case contactSupport
        case tryAgain
    }
}

extension JetpackScan {
    var hasValidCredentials: Bool {
        return credentials?.first?.stillValid ?? false
    }

    var hasFixableThreats: Bool {
        let count = fixableThreats?.count ?? 0
        return count > 0
    }

    var fixableThreats: [JetpackScanThreat]? {
        return threats?.filter { $0.fixable != nil }
    }
}

extension JetpackScan {
    struct Reason {
        static let multiSiteNotSupported = "multisite_not_supported"
    }
}

/// Represents a sorted section of threats
struct JetpackThreatSection {
    let title: String?
    let date: Date
    let threats: [JetpackScanThreat]
}
