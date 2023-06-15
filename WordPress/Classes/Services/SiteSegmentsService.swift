
import Foundation
import WordPressKit


/// Abstracts the service to obtain site types
typealias SiteSegmentsServiceCompletion = (SiteSegmentsResult) -> Void

protocol SiteSegmentsService {
    func siteSegments(completion: @escaping SiteSegmentsServiceCompletion)
}

// MARK: - SiteSegmentsService
final class SiteCreationSegmentsService: SiteSegmentsService {

    // MARK: Properties

    /// A facade for WPCOM services.
    private let remoteService: WordPressComServiceRemote

    init(coreDataStack: CoreDataStack) {
        let api = coreDataStack.performQuery({ context in
            try? WPAccount.lookupDefaultWordPressComAccount(in: context)?.wordPressComRestV2Api
        }) ?? WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress(), localeKey: WordPressComRestApi.LocaleKeyV2)

        self.remoteService = WordPressComServiceRemote(wordPressComRestApi: api)
    }

    // MARK: SiteSegmentsService
    func siteSegments(completion: @escaping SiteSegmentsServiceCompletion) {
        remoteService.retrieveSegments(completion: { result in
                completion(result)
        })
    }
}


// MARK: - Mock

/// Mock implementation of the SeiteSegmentsService
final class MockSiteSegmentsService: SiteSegmentsService {
    func siteSegments(completion: @escaping SiteSegmentsServiceCompletion) {
        let result = SiteSegmentsResult.success(mockSiteTypes)

        completion(result)
    }

    lazy var mockSiteTypes: [SiteSegment] = [
        .withShortSubtitle(identifier: 1),
        .withLongSubtitle(identifier: 2),
        .withShortSubtitle(identifier: 3),
        .withShortSubtitle(identifier: 4)
    ]
}

extension SiteSegment {

    static func withShortSubtitle(identifier: Int64) -> Self {
        .init(
            identifier: identifier,
            title: "Blogger",
            subtitle: "Publish a collection of posts",
            icon: URL(string: "https://s.w.org/style/images/about/WordPress-logotype-standard.png")!,
            iconColor: "#FF0000",
            mobile: true
        )
    }

    static func withLongSubtitle(identifier: Int64) -> Self {
        .init(
            identifier: identifier,
            title: "Professional",
            subtitle: "Showcase your portfolio, skills or work. Expand this to two rows",
            icon: URL(string: "https://s.w.org/style/images/about/WordPress-logotype-standard.png")!,
            iconColor: "#0000FF",
            mobile: true
        )
    }
}
