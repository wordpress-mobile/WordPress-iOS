
import Foundation
import WordPressKit


/// Abstracts the service to obtain site types
typealias SiteSegmentsServiceCompletion = (SiteSegmentsResult) -> Void

protocol SiteSegmentsService {
    func siteSegments(completion: @escaping SiteSegmentsServiceCompletion)
}

// MARK: - SiteSegmentsService
final class SiteCreationSegmentsService: LocalCoreDataService, SiteSegmentsService {

    // MARK: Properties

    /// A service for interacting with WordPress accounts.
    private let accountService: AccountService

    /// A facade for WPCOM services.
    private let remoteService: WordPressComServiceRemote

    // MARK: LocalCoreDataService

    override init(managedObjectContext context: NSManagedObjectContext) {
        self.accountService = AccountService(managedObjectContext: context)

        let userAgent = WPUserAgent.wordPress()
        let localeKey = WordPressComRestApi.LocaleKeyV2

        let api: WordPressComRestApi
        if let account = accountService.defaultWordPressComAccount(), let token = account.authToken {
            api = WordPressComRestApi(oAuthToken: token, userAgent: userAgent, localeKey: localeKey)
        } else {
            api = WordPressComRestApi(userAgent: userAgent, localeKey: localeKey)
        }

        self.remoteService = WordPressComServiceRemote(wordPressComRestApi: api)

        super.init(managedObjectContext: context)
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
                           iconColor: "#FF0000",
                           mobile: true)
    }

    private func longSubtitle(identifier: Int64) -> SiteSegment {
        return SiteSegment(identifier: identifier,
                           title: "Professional",
                           subtitle: "Showcase your portfolio, skills or work. Expand this to two rows",
                           icon: URL(string: "https://s.w.org/style/images/about/WordPress-logotype-standard.png")!,
                           iconColor: "#0000FF",
                           mobile: true)
    }
}
