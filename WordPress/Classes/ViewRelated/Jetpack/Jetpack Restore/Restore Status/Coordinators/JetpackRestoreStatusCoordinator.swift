import Foundation

protocol JetpackRestoreStatusView {
    func render(_ rewindStatus: RewindStatus)
    func showRestoreFailed()
    func showRestoreComplete()
}

class JetpackRestoreStatusCoordinator {

    // MARK: - Properties

    private let service: JetpackRestoreService
    private let site: JetpackSiteRef
    private let view: JetpackRestoreStatusView

    private var timer: Timer?

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

        }, failure: { error in
            DDLogError("Error fetching rewind status object: \(error.localizedDescription)")

            // See: ActivityStore.swift, delayedRetryFetchRewindStatus(site:)
            // if we still have an active query asking about status of this site (e.g. it's still visible on screen)
            // let's keep retrying as long as it's registered — we want users to see the updates.
        })
    }

}

extension JetpackRestoreStatusCoordinator {

    private enum Constants {
        static let pollingInterval: TimeInterval = 5
    }
}
