
import Foundation

/// Working implementation of a `SiteAssemblyService`.
final class EnhancedSiteCreationService: SiteAssemblyService {

    private(set) var currentStatus: SiteAssemblyStatus = .idle
}
