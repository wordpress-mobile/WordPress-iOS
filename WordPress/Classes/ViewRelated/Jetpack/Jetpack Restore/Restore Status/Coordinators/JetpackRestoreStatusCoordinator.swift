import Foundation

protocol JetpackRestoreStatusView {
    func render(_ rewindStatus: RewindStatus)
    func showError()
    func showComplete()
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
            guard let self = self else {
                return
            }

            if rewindStatus.restore?.status == .finished {
                self.view.showComplete()
                return
            }

            self.view.render(rewindStatus)

        }, failure: { error in
            DDLogError("Error fetching rewind status object: \(error.localizedDescription)")

            self.stopPolling()
            self.view.showError()
        })
    }

}

extension JetpackRestoreStatusCoordinator {

    private enum Constants {
        static let pollingInterval: TimeInterval = 5
    }
}
