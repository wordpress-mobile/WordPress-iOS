
import Foundation
import WordPressKit


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
        return [ shortSubtitle(identifier: 1),
                 longSubtitle(identifier: 2),
                 shortSubtitle(identifier: 3),
                 shortSubtitle(identifier: 4) ]
    }()

    var mockCount: Int {
        return mockSiteTypes.count
    }

    private func shortSubtitle(identifier: Int64) -> SiteSegment {
        return SiteSegment(identifier: identifier,
                           title: "Blogger",
                           subtitle: "Publish a collection of posts",
                           icon: URL(string: "https://s.w.org/style/images/about/WordPress-logotype-standard.png")!,
                           iconColor: "FFFFFF",
                           mobile: true)
    }

    private func longSubtitle(identifier: Int64) -> SiteSegment {
        return SiteSegment(identifier: identifier,
                           title: "Professional",
                           subtitle: "Showcase your portfolio, skills or work. Expand this to two rows",
                           icon: URL(string: "https://s.w.org/style/images/about/WordPress-logotype-standard.png")!,
                           iconColor: "FFFFFF",
                           mobile: true)
    }
}
