
import Foundation


/// Abstracts the service to obtain site types
typealias SiteSegmentsServiceCompletion = (Result<[SiteSegment]>) -> Void

protocol SiteSegmentsService {
    func siteSegments(for: Locale, completion: @escaping SiteSegmentsServiceCompletion)
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

        let api: WordPressComRestApi
        if let wpcomApi = accountService.defaultWordPressComAccount()?.wordPressComRestApi {
            api = wpcomApi
        } else {
            api = WordPressComRestApi(userAgent: WPUserAgent.wordPress())
        }
        self.remoteService = WordPressComServiceRemote(wordPressComRestApi: api)

        super.init(managedObjectContext: context)
    }

    // MARK: SiteSegmentsService
    func siteSegments(for: Locale, completion: @escaping SiteSegmentsServiceCompletion) {
        remoteService.retrieveSegments(completion: completion)
    }

//    func retrieveVerticals(request: SiteVerticalsRequest, completion: @escaping SiteVerticalsServiceCompletion) {
//        remoteService.retrieveVerticals(request: request) { result in
//            completion(result)
//        }
//    }
}


// MARK: - Mock

/// Mock implementation of the SeiteSegmentsService
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
                           iconColor: .red)
    }

    private func longSubtitle(identifier: Int64) -> SiteSegment {
        return SiteSegment(identifier: identifier,
                           title: "Professional",
                           subtitle: "Showcase your portfolio, skills or work. Expand this to two rows",
                           icon: URL(string: "https://s.w.org/style/images/about/WordPress-logotype-standard.png")!,
                           iconColor: .blue)
    }
}
