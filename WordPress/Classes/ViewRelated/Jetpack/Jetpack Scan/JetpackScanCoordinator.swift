import Foundation

protocol JetpackScanView {
    func render(_ scan: JetpackScan)

    func showLoading()
    func showError()
}

class JetpackScanCoordinator {
    private let service: JetpackScanService
    private let site: JetpackSiteRef
    private let view: JetpackScanView

    private(set) var scan: JetpackScan?

    init(site: JetpackSiteRef,
         view: JetpackScanView,
        service: JetpackScanService? = nil,
        context: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {

        self.service = service ?? JetpackScanService(managedObjectContext: context)
        self.site = site
        self.view = view
    }

    public func start() {
        view.showLoading()

        service.getScan(for: site) { [weak self] scanObj in
            self?.scan = scanObj
            self?.view.render(scanObj)
        } failure: { [weak self] error in
            DDLogError("Error fetching scan object: \(String(describing: error.localizedDescription))")

            self?.view.showError()
        }
    }
}
