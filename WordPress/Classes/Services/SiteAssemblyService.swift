
import Foundation

/// Working implementation of a `SiteAssemblyService`.
final class EnhancedSiteCreationService: SiteAssemblyService {

    private(set) var currentStatus: SiteAssemblyStatus = .idle {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.statusChangeHandler?(strongSelf.currentStatus)
            }
        }
    }

    private(set) var statusChangeHandler: SiteAssemblyStatusChangedHandler?

    func createSite(creatorOutput assemblyInput: SiteCreatorOutput, changeHandler: SiteAssemblyStatusChangedHandler? = nil) {
        self.statusChangeHandler = changeHandler
    }
}
