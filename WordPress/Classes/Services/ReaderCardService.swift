import Foundation

class ReaderCardService {
    private let service: ReaderPostServiceRemote
    private let coreDataStack: CoreDataStack
    private lazy var syncContext: NSManagedObjectContext = {
        return coreDataStack.newDerivedContext()
    }()

    init(service: ReaderPostServiceRemote = ReaderPostServiceRemote(wordPressComRestApi: WordPressComMockrestApi()),
         coreDataStack: CoreDataStack = ContextManager.shared) {
        self.service = service
        self.coreDataStack = coreDataStack
    }

    func fetch(page: Int = 1, success: @escaping (Int, Bool) -> Void, failure: @escaping (Error?) -> Void) {
        service.fetchCards(for: ["foo", "bar"],
                           success: { [weak self] cards in

                            guard let syncContext = self?.syncContext else {
                                return
                            }

                            syncContext.perform {

                                if page == Constants.firstPage {
                                    self?.removeAllCards()
                                }

                                cards.enumerated().forEach { index, remoteCard in
                                    let card = ReaderCard(context: syncContext, from: remoteCard)

                                    // To keep the API order
                                    card?.sortRank = Double((page * Constants.paginationMultiplier) + index)
                                }
                            }

                            self?.coreDataStack.save(syncContext) {
                                success(cards.count, true)
                            }
        }, failure: { error in
            failure(error)
        })
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
