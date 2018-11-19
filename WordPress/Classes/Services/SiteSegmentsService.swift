
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
        return [ shortSubtitle(id: "Site Id 1"),
                 longSubtitle(id: "Site Id 2"),
                 shortSubtitle(id: "Site Id 3"),
                 shortSubtitle(id: "Site Id 4") ]
    }()

    var mockCount: Int {
        return mockSiteTypes.count
    }

    private func shortSubtitle(id: String) -> SiteSegment {
        let identifier = Identifier(value: id)
        return SiteSegment(identifier: identifier,
                           title: "Blogger",
                           subtitle: "Publish a collection of posts",
                           icon: URL(string: "https://s.w.org/style/images/about/WordPress-logotype-standard.png")!)
    }

    private func longSubtitle(id: String) -> SiteSegment {
        let identifier = Identifier(value: id)
        return SiteSegment(identifier: identifier,
                           title: "Professional",
                           subtitle: "Showcase your portfolio, skills or work. Expand this to two rows",
                           icon: URL(string: "https://s.w.org/style/images/about/WordPress-logotype-standard.png")!)
    }
}
