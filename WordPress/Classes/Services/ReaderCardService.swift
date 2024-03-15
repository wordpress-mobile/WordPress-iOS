import Foundation

protocol ReaderCardServiceRemote {

    func fetchStreamCards(for topics: [String],
                          page: String?,
                          sortingOption: ReaderSortingOption,
                          refreshCount: Int?,
                          count: Int?,
                          success: @escaping ([RemoteReaderCard], String?) -> Void,
                          failure: @escaping (Error) -> Void)

    func fetchCards(for topics: [String],
                    page: String?,
                    sortingOption: ReaderSortingOption,
                    refreshCount: Int?,
                    success: @escaping ([RemoteReaderCard], String?) -> Void,
                    failure: @escaping (Error) -> Void)

}

extension ReaderPostServiceRemote: ReaderCardServiceRemote { }

class ReaderCardService {
    private let service: ReaderCardServiceRemote

    private let coreDataStack: CoreDataStack

    private let followedInterestsService: ReaderFollowedInterestsService
    private let siteInfoService: ReaderSiteInfoService

    /// An string used to retrieve the next page
    private var pageHandle: String?

    /// Used only internally to order the cards
    private var pageNumber = 1

    init(service: ReaderCardServiceRemote = ReaderPostServiceRemote.withDefaultApi(),
         coreDataStack: CoreDataStack = ContextManager.shared,
         followedInterestsService: ReaderFollowedInterestsService? = nil,
         siteInfoService: ReaderSiteInfoService? = nil) {
        self.service = service
        self.coreDataStack = coreDataStack
        self.followedInterestsService = followedInterestsService ?? ReaderTopicService(coreDataStack: coreDataStack)
        self.siteInfoService = siteInfoService ?? ReaderTopicService(coreDataStack: coreDataStack)
    }

    func fetch(isFirstPage: Bool, refreshCount: Int = 0, success: @escaping (Int, Bool) -> Void, failure: @escaping (Error?) -> Void) {
        followedInterestsService.fetchFollowedInterestsLocally { [weak self] topics in
            guard let self,
                  let interests = topics,
                  !interests.isEmpty else {
                failure(Errors.noInterests)
                return
            }

            let slugs = interests.map { $0.slug }
            let success: ([RemoteReaderCard], String?) -> Void = { [weak self] cards, pageHandle in
                guard let self else {
                    return
                }
                var updatedCards = cards
                let isCardTags = updatedCards.first?.type == .interests
                let isCardSites = updatedCards.first?.type == .sites
                if isFirstPage && (isCardTags || isCardSites) && updatedCards.count > 2 {
                    // Move the first tags recommendation card to a lower position
                    updatedCards.move(fromOffsets: IndexSet(integer: 0), toOffset: 3)
                }

                self.pageHandle = pageHandle

                self.coreDataStack.performAndSave({ context in
                    if isFirstPage {
                        self.pageNumber = 1
                        self.removeAllCards(in: context)
                    } else {
                        self.pageNumber += 1
                    }

                    updatedCards.enumerated().forEach { index, remoteCard in
                        let card = ReaderCard(context: context, from: remoteCard)

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
                }, completion: {
                    let hasMore = pageHandle != nil
                    success(cards.count, hasMore)
                }, on: .main)
            }
            let failure: (Error?) -> Void = { error in
                failure(error)
            }

            if RemoteFeatureFlag.readerDiscoverEndpoint.enabled() {
                self.service.fetchStreamCards(for: slugs,
                                              page: self.pageHandle(isFirstPage: isFirstPage),
                                              sortingOption: .noSorting,
                                              refreshCount: refreshCount,
                                              count: nil,
                                              success: success,
                                              failure: failure)
            } else {
                self.service.fetchCards(for: slugs,
                                        page: self.pageHandle(isFirstPage: isFirstPage),
                                        sortingOption: .noSorting,
                                        refreshCount: refreshCount,
                                        success: success,
                                        failure: failure)
            }
        }
    }

    /// Remove all cards and saves the context
    func clean() {
        coreDataStack.performAndSave { context in
            self.removeAllCards(in: context)
        }
    }

    private func removeAllCards(in context: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderCard.classNameWithoutNamespaces())
        fetchRequest.returnsObjectsAsFaults = false

        do {
            let results = try context.fetch(fetchRequest)
            for object in results {
                guard let objectData = object as? NSManagedObject else { continue }
                context.delete(objectData)
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

        let defaultAccount = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
        let token: String? = defaultAccount?.authToken

        let api = WordPressComRestApi.defaultApi(oAuthToken: token,
                                              userAgent: WPUserAgent.wordPress(),
                                              localeKey: WordPressComRestApi.LocaleKeyV2)
        return ReaderPostServiceRemote(wordPressComRestApi: api)
    }
}
