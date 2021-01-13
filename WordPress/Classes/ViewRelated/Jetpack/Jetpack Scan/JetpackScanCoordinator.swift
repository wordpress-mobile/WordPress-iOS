import Foundation

protocol JetpackScanView {
    func render(_ scan: JetpackScan)

    func showLoading()
    func showError()
}

class JetpackScanCoordinator {
    private let service: JetpackScanService
    private let blog: Blog
    private let view: JetpackScanView

    private(set) var scan: JetpackScan?

    /// Returns the threats if we're in the idle state
    var threats: [JetpackScanThreat]? {
        return scan?.state == .idle ? scan?.threats : nil
    }

    init(blog: Blog,
         view: JetpackScanView,
         service: JetpackScanService? = nil,
         context: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {

        self.service = service ?? JetpackScanService(managedObjectContext: context)
        self.blog = blog
        self.view = view
    }

    public func refreshData(showLoading: Bool = false) {
        if showLoading {
            view.showLoading()
        }

        service.getScan(for: blog) { [weak self] scanObj in
            self?.scan = scanObj
            self?.view.render(scanObj)
        } failure: { [weak self] error in
            DDLogError("Error fetching scan object: \(String(describing: error.localizedDescription))")

            self?.view.showError()
        }
    }
}
