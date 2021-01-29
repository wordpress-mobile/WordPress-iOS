import Foundation

protocol JetpackScanThreatDetailsView {
    func showFixThreatSuccess()
    func showFixThreatError()
    func showIgnoreThreatSuccess()
    func showIgnoreThreatError()
}

class JetpackScanThreatDetailsCoordinator {

    // MARK: - Properties

    private let service: JetpackScanService
    private let blog: Blog
    private let threat: JetpackScanThreat
    private let view: JetpackScanThreatDetailsView

    // MARK: - Init

    init(blog: Blog,
         threat: JetpackScanThreat,
         view: JetpackScanThreatDetailsView,
         service: JetpackScanService? = nil,
         context: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {

        self.service = service ?? JetpackScanService(managedObjectContext: context)
        self.blog = blog
        self.threat = threat
        self.view = view
    }

    // MARK: - Public

    public func fixThreat() {
        service.fixThreat(threat, blog: blog, success: { [weak self] _ in
            self?.view.showFixThreatSuccess()
        }, failure: { [weak self] error in
            DDLogError("Error fixing threat: \(error.localizedDescription)")

            self?.view.showFixThreatError()
        })
    }

    public func ignoreThreat() {

    }
}
