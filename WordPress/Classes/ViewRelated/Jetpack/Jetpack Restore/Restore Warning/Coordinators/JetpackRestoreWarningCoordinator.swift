import Foundation

protocol JetpackRestoreWarningView {
    func showNoInternetConnection()
    func showRestoreAlreadyRunning()
    func showRestoreRequestFailed()
    func showRestoreStarted()
}

class JetpackRestoreWarningCoordinator {

    // MARK: - Properties

    private let service: JetpackRestoreService
    private let site: JetpackSiteRef
    private let rewindID: String?
    private let restoreTypes: JetpackRestoreTypes
    private let view: JetpackRestoreWarningView

    // MARK: - Init

    init(site: JetpackSiteRef,
         restoreTypes: JetpackRestoreTypes,
         rewindID: String?,
         view: JetpackRestoreWarningView,
         service: JetpackRestoreService? = nil,
         context: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {
        self.service = service ?? JetpackRestoreService(managedObjectContext: context)
        self.site = site
        self.rewindID = rewindID
        self.restoreTypes = restoreTypes
        self.view = view
    }

    // MARK: - Public

    func restoreSite() {
        guard ReachabilityUtils.isInternetReachable() else {
            self.view.showNoInternetConnection()
            return
        }

        service.restoreSite(site, rewindID: rewindID, restoreTypes: restoreTypes, success: { [weak self] _, jobID in

            if jobID == 0 {
                self?.view.showRestoreAlreadyRunning()
                return
            }

            self?.view.showRestoreStarted()

        }, failure: { [weak self] error in
            DDLogError("Error restoring site: \(error.localizedDescription)")

            self?.view.showRestoreRequestFailed()
        })
    }
}
