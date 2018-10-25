
import Foundation


/// Abstracts the service to obtain site types
typealias SitesTypeServiceCompletion = (Result<[NewSiteType]>) -> Void

protocol SiteTypesService {
    func siteTypes(for: Locale, completion: @escaping SitesTypeServiceCompletion)
}


/// Mock implementation so that we can start developing
final class MockSiteTypesService: SiteTypesService {
    func siteTypes(for: Locale, completion: @escaping SitesTypeServiceCompletion) {
        let result = Result.success(mockSiteTypes())

        completion(result)
    }

    private func mockSiteTypes() -> [NewSiteType] {
        return [ singleSiteType(id: "Site Id 1"),
                 singleSiteType(id: "Site Id 2"),
                 singleSiteType(id: "Site Id 3"),
                 singleSiteType(id: "Site Id 4") ]
    }

    private func singleSiteType(id: String) -> NewSiteType {
        let identifier = Identifier(value: id)
        return NewSiteType(id: identifier,
                           title: "Mock",
                           subtitle: "Mock subtitle",
                           icon: URL(string: "https://s.w.org/style/images/about/WordPress-logotype-standard.png")!)
    }
}
