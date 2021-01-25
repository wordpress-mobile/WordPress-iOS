import Foundation

protocol JetpackRestoreStatusView {
    func render(_ rewindStatus: RewindStatus)
    func showRestoreStatusUpdateFailed()
    func showRestoreFailed()
    func showRestoreComplete()
}

class JetpackRestoreStatusCoordinator {

    // MARK: - Properties

    private let service: JetpackRestoreService
    private let site: JetpackSiteRef
    private let view: JetpackRestoreStatusView

    private var timer: Timer?
    private var retryCount: Int = 0

    // MARK: - Init

    init(site: JetpackSiteRef,
         view: JetpackRestoreStatusView,
         service: JetpackRestoreService? = nil,
         context: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {
        self.service = service ?? JetpackRestoreService(managedObjectContext: context)
        self.site = site
        self.view = view
    }

    // MARK: - Public

    func viewDidLoad() {
        startPolling()
    }

    func viewWillDisappear() {
        stopPolling()
    }

    // MARK: - Private

    private func startPolling() {
        guard timer == nil else {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: Constants.pollingInterval, repeats: true) { [weak self] _ in
            self?.refreshRestoreStatus()
        }
    }

    private func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    private func refreshRestoreStatus() {
        service.getRewindStatus(for: self.site, success: { [weak self] rewindStatus in
            guard let self = self, let restoreStatus = rewindStatus.restore else {
                return
            }

            switch restoreStatus.status {
            case .running, .queued:
                self.view.render(rewindStatus)
            case .finished:
                self.view.showRestoreComplete()
            case .fail:
                self.view.showRestoreFailed()
            }

        }, failure: { [weak self] error in
            DDLogError("Error fetching rewind status object: \(error.localizedDescription)")

            guard let self = self else {
                return
            }

            if self.retryCount == Constants.maxRetryCount {
                self.stopPolling()
                self.view.showRestoreStatusUpdateFailed()
                return
            }

            self.retryCount += 1
        })
    }

}

extension JetpackRestoreStatusCoordinator {

    private enum Constants {
        static let pollingInterval: TimeInterval = 5
        static let maxRetryCount: Int = 3
    }
}
