import Foundation

protocol JetpackBackupStatusView {
    func render(_ backup: JetpackBackup)
    func showLoading()
    func showError()
}

class JetpackBackupStatusCoordinator {

    private let service: JetpackBackupService
    private let blog: Blog
    private let view: JetpackBackupStatusView

    private(set) var backup: JetpackBackup?

    init(blog: Blog,
         view: JetpackBackupStatusView,
         service: JetpackBackupService? = nil,
         context: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {

        self.service = service ?? JetpackBackupService(managedObjectContext: context)
        self.blog = blog
        self.view = view
    }

    func start() {
        view.showLoading()

//        service.prepareBackup(for: blog, success: { [weak self] backup in
//            self?.backup = backup
//            self?.view.render(backup)
//        }, failure: { [weak self] error in
//            DDLogError("Error preparing downloadable backup object: \(String(describing: error.localizedDescription))")
//
//            self?.view.showError()
//        })

        service.getBackupStatus(for: blog, success: { [weak self] backup in
            self?.backup = backup
            self?.view.render(backup)
        }, failure: { [weak self] error in
            DDLogError("Error fetching backup object: \(error.localizedDescription)")

            self?.view.showError()
        })
    }


}
