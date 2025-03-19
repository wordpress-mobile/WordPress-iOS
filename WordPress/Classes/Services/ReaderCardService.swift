import Foundation
import WordPressKit
import WordPressShared

protocol ReaderCardServiceRemote {
    func fetchStreamCards(stream: ReaderStream,
                          for topics: [String],
                          page: String?,
                          sortingOption: ReaderSortingOption,
                          refreshCount: Int?,
                          count: Int?,
                          success: @escaping ([RemoteReaderCard], String?) -> Void,
                          failure: @escaping (Error) -> Void)

}

extension ReaderPostServiceRemote: ReaderCardServiceRemote { }

class ReaderCardService {
    private let stream: ReaderStream
    private let sorting: ReaderSortingOption
    private let service: ReaderCardServiceRemote

    private let coreDataStack: CoreDataStack

    private let followedInterestsService: ReaderFollowedInterestsService
    private let siteInfoService: ReaderSiteInfoService

    /// An string used to retrieve the next page
    private var pageHandle: String?

    /// Used only internally to order the cards
    private var pageNumber = 1

    init(stream: ReaderStream = .discover,
         sorting: ReaderSortingOption = .noSorting,
         service: ReaderCardServiceRemote = ReaderPostServiceRemote.withDefaultApi(),
         coreDataStack: CoreDataStack = ContextManager.shared,
         followedInterestsService: ReaderFollowedInterestsService? = nil,
         siteInfoService: ReaderSiteInfoService? = nil) {
        self.stream = stream
        self.sorting = sorting
        self.service = service
        self.coreDataStack = coreDataStack
        self.followedInterestsService = followedInterestsService ?? ReaderTopicService(coreDataStack: coreDataStack)
        self.siteInfoService = siteInfoService ?? ReaderTopicService(coreDataStack: coreDataStack)
    }

    func fetch(isFirstPage: Bool, refreshCount: Int = 0, success: @escaping (Int, Bool) -> Void, failure: @escaping (Error?) -> Void) {
        followedInterestsService.fetchFollowedInterestsLocally { [weak self] topics in
            guard let self, let interests = topics else {
                failure(URLError(.unknown)) // Should never happen
                return
            }

            var slugs = interests.map { $0.slug }
            if slugs.isEmpty {
                slugs = ["dailyprompt", "wordpress"] // Matches wp.com
            }
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
                        ReaderCardService.removeAllCards(in: context)
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

            self.service.fetchStreamCards(
                stream: self.stream,
                for: slugs,
                page: self.pageHandle(isFirstPage: isFirstPage),
                sortingOption: self.sorting,
                refreshCount: refreshCount,
                count: nil,
                success: success,
                failure: failure
            )
        }
    }

    /// Remove all cards and saves the context
    func clean() {
        ReaderCardService.removeAllCards(on: coreDataStack)
    }

    static func removeAllCards(on stack: CoreDataStack = ContextManager.shared) {
        stack.performAndSave { context in
            removeAllCards(in: context)
        }
    }

    private static func removeAllCards(in context: NSManagedObjectContext) {
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
