import Foundation

class ReaderCardService {
    private let service: ReaderPostServiceRemote
    private let coreDataStack: CoreDataStack
    private let followedInterestsService: ReaderFollowedInterestsService
    private lazy var syncContext: NSManagedObjectContext = {
        return coreDataStack.newDerivedContext()
    }()

    init(service: ReaderPostServiceRemote = ReaderPostServiceRemote(wordPressComRestApi: WordPressComMockrestApi()),
         coreDataStack: CoreDataStack = ContextManager.shared,
         followedInterestsService: ReaderFollowedInterestsService? = nil) {
        self.service = service
        self.coreDataStack = coreDataStack
        self.followedInterestsService = followedInterestsService ?? ReaderTopicService(managedObjectContext: coreDataStack.mainContext)
    }

    func fetch(page: Int = 1, success: @escaping (Int, Bool) -> Void, failure: @escaping (Error?) -> Void) {
        followedInterestsService.fetchFollowedInterestsLocally { [unowned self] topics in
            guard let interests = topics, !interests.isEmpty else {
                failure(Errors.noInterests)
                return
            }

            let slugs = interests.map { $0.slug }
            self.service.fetchCards(for: slugs,
                               success: { [weak self] cards in

                                guard let self = self else {
                                    return
                                }

                                self.syncContext.perform {

                                    if page == Constants.firstPage {
                                        self.removeAllCards()
                                    }

                                    cards.enumerated().forEach { index, remoteCard in
                                        let card = ReaderCard(context: self.syncContext, from: remoteCard)

                                        // Assign each interest an endpoint
                                        card?
                                            .topics?
                                            .array
                                            .compactMap { $0 as? ReaderTagTopic }
                                            .forEach { $0.path = self.followedInterestsService.path(slug: $0.slug) }

                                        // To keep the API order
                                        card?.sortRank = Double((page * Constants.paginationMultiplier) + index)
                                    }
                                }

                                self.coreDataStack.save(self.syncContext) {
                                    success(cards.count, true)
                                }
            }, failure: { error in
                failure(error)
            })

        }
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

    enum Errors: Error {
        case noInterests
    }

    private enum Constants {
        static let paginationMultiplier = 100
        static let firstPage = 1
    }
}

// RI2: The Cards API is not ready yet, that's why we're mocking it here
class WordPressComMockrestApi: WordPressComRestApi {
    override func GET(_ URLString: String, parameters: [String: AnyObject]?, success: @escaping WordPressComRestApi.SuccessResponseBlock, failure: @escaping WordPressComRestApi.FailureReponseBlock) -> Progress? {
        guard
            let fileURL: URL = Bundle.main.url(forResource: "reader-cards-success.json", withExtension: nil),
            let data: Data = try? Data(contentsOf: fileURL),
            let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as AnyObject
        else {
            return Progress()
        }

        success(jsonObject, nil)
        return Progress()
    }
}
