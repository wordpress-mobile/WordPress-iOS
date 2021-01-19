import Foundation

protocol JetpackRestoreStatusView {
    func render(_ rewindStatus: RewindStatus)
    func showError()
    func showComplete()
}

class JetpackRestoreStatusCoordinator {

    private let service: JetpackRestoreService
    private let rewindID: String?
    private let site: JetpackSiteRef
    private let view: JetpackRestoreStatusView

    init(site: JetpackSiteRef,
         rewindID: String?,
         view: JetpackRestoreStatusView,
         service: JetpackRestoreService? = nil,
         context: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {
        self.service = service ?? JetpackRestoreService(managedObjectContext: context)
        self.site = site
        self.rewindID = rewindID
        self.view = view
    }

    func start() {
        service.restoreSite(site, rewindID: rewindID, success: { [weak self] _ in
            self?.pollRestoreStatus()
        }, failure: { [weak self] error in
            DDLogError("Error restoring site: \(error.localizedDescription)")

            self?.view.showError()
        })
    }

    private func pollRestoreStatus() {
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] timer in
            guard let self = self else { return }

            self.service.getRewindStatus(for: self.site, success: { rewindStatus in

                if rewindStatus.restore?.status == .finished {
                    timer.invalidate()
                    self.view.showComplete()
                    return
                }

                self.view.render(rewindStatus)

            }, failure: { error in
                DDLogError("Error fetching rewind status object: \(error.localizedDescription)")

                timer.invalidate()
                self.view.showError()
            })
        }
    }

}
