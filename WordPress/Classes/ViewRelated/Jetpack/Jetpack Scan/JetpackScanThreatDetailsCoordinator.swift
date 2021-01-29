import UIKit

protocol JetpackScanThreatDetailsView {
    func showError()
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

    }

    public func ignoreThreat() {

    }
}
