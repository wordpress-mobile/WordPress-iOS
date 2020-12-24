import Foundation

class ReaderCardService {
    private let service: ReaderPostServiceRemote

    private let coreDataStack: CoreDataStack

    private let followedInterestsService: ReaderFollowedInterestsService
    private let siteInfoService: ReaderSiteInfoService

    private lazy var syncContext: NSManagedObjectContext = {
        return coreDataStack.newDerivedContext()
    }()

    /// An string used to retrieve the next page
    private var pageHandle: String?

    /// Used only internally to order the cards
    private var pageNumber = 1

    init(service: ReaderPostServiceRemote = ReaderPostServiceRemote.withDefaultApi(),
         coreDataStack: CoreDataStack = ContextManager.shared,
         followedInterestsService: ReaderFollowedInterestsService? = nil,
         siteInfoService: ReaderSiteInfoService? = nil) {
        self.service = service
        self.coreDataStack = coreDataStack
        self.followedInterestsService = followedInterestsService ?? ReaderTopicService(managedObjectContext: coreDataStack.mainContext)
        self.siteInfoService = siteInfoService ?? ReaderTopicService(managedObjectContext: coreDataStack.mainContext)
    }

    func fetch(isFirstPage: Bool, refreshCount: Int = 0, success: @escaping (Int, Bool) -> Void, failure: @escaping (Error?) -> Void) {
        followedInterestsService.fetchFollowedInterestsLocally { [unowned self] topics in
            guard let interests = topics, !interests.isEmpty else {
                failure(Errors.noInterests)
                return
            }

            let slugs = interests.map { $0.slug }
            self.service.fetchCards(for: slugs,
                                    page: self.pageHandle(isFirstPage: isFirstPage),
                                    refreshCount: refreshCount,
                               success: { [weak self] cards, pageHandle in

                                guard let self = self else {
                                    return
                                }

                                self.pageHandle = pageHandle

                                self.syncContext.perform {

                                    if isFirstPage {
                                        self.pageNumber = 1
                                        self.removeAllCards()
                                    } else {
                                        self.pageNumber += 1
                                    }

                                    cards.enumerated().forEach { index, remoteCard in
                                        let card = ReaderCard(context: self.syncContext, from: remoteCard)

                                        // Assign each interest an endpoint
                                        card?
                                            .topics?
                                            .array
                                            .compactMap { $0 as? ReaderTagTopic }
                                            .forEach { $0.path = self.followedInterestsService.path(slug: $0.slug) }

                                        // Assign each site an endpoint URL if needed
                                        card?
                                            .sites?
                                            .array
                                            .compactMap { $0 as? ReaderSiteTopic }
                                            .forEach {
                                                let path = $0.path
                                                // Sites coming from the cards API only have a path and not a full url
                                                // Once we save the model locally it will be a full URL, so we don't
                                                // want to reapply this logic
                                                if !path.hasPrefix("http") {
                                                    $0.path = self.siteInfoService.endpointURLString(path: path)
                                                }
                                            }

                                        // To keep the API order
                                        card?.sortRank = Double((self.pageNumber * Constants.paginationMultiplier) + index)
                                    }
                                }

                                self.coreDataStack.save(self.syncContext) {
                                    let hasMore = pageHandle != nil
                                    success(cards.count, hasMore)
                                }
            }, failure: { error in
                failure(error)
            })

        }
    }

    /// Remove all cards and saves the context
    func clean() {
        removeAllCards()
        coreDataStack.save(syncContext)
    }

    private func removeAllCards() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderCard.classNameWithoutNamespaces())
        fetchRequest.returnsObjectsAsFaults = false

        do {
            let results = try syncContext.fetch(fetchRequest)
            for object in results {
                guard let objectData = object as? NSManagedObject else { continue }
                syncContext.delete(objectData)
            }
        } catch let error {
            print("Clean card error:", error)
        }
    }

    private func pageHandle(isFirstPage: Bool) -> String? {
        isFirstPage ? nil : self.pageHandle
    }

    enum Errors: Error {
        case noInterests
    }

    private enum Constants {
        static let paginationMultiplier = 100
        static let firstPage = 1
    }
}

/// Used to inject the ReaderPostServiceRemote as an dependency
extension ReaderPostServiceRemote {
    class func withDefaultApi() -> ReaderPostServiceRemote {
        let accountService = AccountService(managedObjectContext: ContextManager.shared.mainContext)
        let defaultAccount = accountService.defaultWordPressComAccount()
        let token: String? = defaultAccount?.authToken

        let api = WordPressComRestApi.defaultApi(oAuthToken: token,
                                              userAgent: WPUserAgent.wordPress(),
                                              localeKey: WordPressComRestApi.LocaleKeyV2)
        return ReaderPostServiceRemote(wordPressComRestApi: api)
    }
}
