import Foundation

class ReaderCardService {
    private let service: ReaderPostServiceRemote
    private let coreDataStack: CoreDataStack

    init(service: ReaderPostServiceRemote = ReaderPostServiceRemote(wordPressComRestApi: WordPressComMockrestApi()),
         coreDataStack: CoreDataStack = ContextManager.shared) {
        self.service = service
        self.coreDataStack = coreDataStack
    }

    func fetch(success: @escaping (Int, Bool) -> Void, failure: @escaping (Error?) -> Void) {
        service.fetchCards(for: ["foo", "bar"],
                           success: { [unowned self] cards in
                            let syncContext = self.coreDataStack.newDerivedContext()

                            syncContext.perform {
                                cards.forEach { remoteCard in
                                    guard remoteCard.type != .unknown else {
                                        return
                                    }

                                    let card = ReaderCard(context: syncContext)

                                    switch remoteCard.type {
                                    case .post:
                                        card.post = ReaderPost.createOrReplace(fromRemotePost: remoteCard.post, for: nil, context: syncContext)
                                    default:
                                        break
                                    }

                                    card.sortRank = Date().timeIntervalSince1970
                                }
                            }

                            self.coreDataStack.save(syncContext) {
                                success(cards.count, true)
                            }
        }, failure: { error in
            failure(error)
        })
    }
}

// RI2: The Cards API is not ready yet, that's why we're mocking it here
class WordPressComMockrestApi: WordPressComRestApi {
    override func GET(_ URLString: String, parameters: [String : AnyObject]?, success: @escaping WordPressComRestApi.SuccessResponseBlock, failure: @escaping WordPressComRestApi.FailureReponseBlock) -> Progress? {
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
