
import Foundation


/// Abstracts the service to obtain site types
typealias SiteSegmentsServiceCompletion = (Result<[SiteSegment]>) -> Void

protocol SiteSegmentsService {
    func siteSegments(for: Locale, completion: @escaping SiteSegmentsServiceCompletion)
}


/// Mock implementation so that we can start developing
final class MockSiteSegmentsService: SiteSegmentsService {
    func siteSegments(for: Locale = .current, completion: @escaping SiteSegmentsServiceCompletion) {
        let result = Result.success(mockSiteTypes)

        completion(result)
    }

    lazy var mockSiteTypes: [SiteSegment] = {
        return [ singleSiteType(id: "Site Id 1"),
                 singleSiteType(id: "Site Id 2"),
                 singleSiteType(id: "Site Id 3"),
                 singleSiteType(id: "Site Id 4") ]
    }()

    var mockCount: Int {
        return mockSiteTypes.count
    }

    private func singleSiteType(id: String) -> SiteSegment {
        let identifier = Identifier(value: id)
        return SiteSegment(identifier: identifier,
                           title: "Mock",
                           subtitle: "Showcase your portfolio, skills or work",
                           icon: URL(string: "https://s.w.org/style/images/about/WordPress-logotype-standard.png")!)
    }
}
