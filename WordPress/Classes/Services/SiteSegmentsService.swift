
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
