import Foundation

protocol JetpackBackupOptionsView {
    func showNoInternetConnection()
    func showBackupAlreadyRunning()
    func showBackupRequestFailed()
    func showBackupStarted(for downloadID: Int)
}

class JetpackBackupOptionsCoordinator {

    // MARK: - Properties

    private let service: JetpackBackupService
    private let site: JetpackSiteRef
    private let rewindID: String?
    private let restoreTypes: JetpackRestoreTypes
    private let view: JetpackBackupOptionsView

    // MARK: - Init

    init(site: JetpackSiteRef,
         rewindID: String?,
         restoreTypes: JetpackRestoreTypes,
         view: JetpackBackupOptionsView,
         service: JetpackBackupService? = nil,
         context: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {
        self.service = service ?? JetpackBackupService(managedObjectContext: context)
        self.site = site
        self.rewindID = rewindID
        self.restoreTypes = restoreTypes
        self.view = view
    }

    // MARK: - Public

    func prepareBackup() {
        guard ReachabilityUtils.isInternetReachable() else {
            self.view.showNoInternetConnection()
            return
        }

        service.prepareBackup(for: site, rewindID: rewindID, restoreTypes: restoreTypes, success: { [weak self] backup in

            guard let rewindID = self?.rewindID, rewindID == backup.rewindID else {
                self?.view.showBackupAlreadyRunning()
                return
            }

            self?.view.showBackupStarted(for: backup.downloadID)

        }, failure: { [weak self] error in
            DDLogError("Error preparing downloadable backup object: \(error.localizedDescription)")

            self?.view.showBackupRequestFailed()
        })
    }
}
