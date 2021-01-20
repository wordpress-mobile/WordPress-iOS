import Foundation

protocol JetpackBackupStatusView {
    func render(_ backup: JetpackBackup)
    func showError()
    func showComplete(_ backup: JetpackBackup)
}

class JetpackBackupStatusCoordinator {

    // MARK: - Properties

    private let service: JetpackBackupService
    private let site: JetpackSiteRef
    private let downloadID: Int
    private let view: JetpackBackupStatusView

    private var timer: Timer?

    // MARK: - Init

    init(site: JetpackSiteRef,
         downloadID: Int,
         view: JetpackBackupStatusView,
         service: JetpackBackupService? = nil,
         context: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {
        self.service = service ?? JetpackBackupService(managedObjectContext: context)
        self.site = site
        self.downloadID = downloadID
        self.view = view
    }

    // MARK: - Public

    func viewDidLoad() {
        startPolling(for: downloadID)
    }

    func viewWillDisappear() {
        stopPolling()
    }

    // MARK: - Private

    private func startPolling(for downloadID: Int) {
        guard timer == nil else {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: Constants.pollingInterval, repeats: true) { [weak self] timer in
            self?.refreshBackupStatus(downloadID: downloadID)
        }
    }

    private func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    private func refreshBackupStatus(downloadID: Int) {
        service.getBackupStatus(for: self.site, downloadID: downloadID, success: { [weak self] backup in
            guard let self = self else {
                return
            }

            // If a backup url exists, then we've finished creating a downloadable backup.
            if backup.url != nil {
                self.view.showComplete(backup)
                return
            }

            self.view.render(backup)

        }, failure: { [weak self] error in
            DDLogError("Error fetching backup object: \(error.localizedDescription)")

            self?.stopPolling()
            self?.view.showError()
        })
    }

}

extension JetpackBackupStatusCoordinator {

    private enum Constants {
        static let pollingInterval: TimeInterval = 1
    }
}
