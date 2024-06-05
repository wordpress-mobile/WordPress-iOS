import Foundation

class ReaderPostStreamService {

    private let coreDataStack: CoreDataStack

    private var nextPageHandle: String?
    private var pageNumber: Int = 0

    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }

    func fetchPosts(for topic: ReaderTagTopic, isFirstPage: Bool = true, success: @escaping (Int, Bool) -> Void, failure: @escaping (Error?) -> Void) {
        if isFirstPage {
            nextPageHandle = nil
        }

        let remoteService = ReaderPostServiceRemote.withDefaultApi()
        remoteService.fetchPosts(for: [topic.slug], page: nextPageHandle, success: { posts, pageHandle in
            self.coreDataStack.performAndSave({ context in
                guard let readerTopic = try? context.existingObject(with: topic.objectID) as? ReaderAbstractTopic else {
                    // if there was an error or the topic was deleted just bail.
                    success(0, false)
                    return
                }

                self.nextPageHandle = pageHandle

                if isFirstPage {
                    self.pageNumber = 1
                    self.removePosts(forTopic: readerTopic, in: context)
                } else {
                    self.pageNumber += 1
                }

                posts.enumerated().forEach { index, remotePost in
                    let post = ReaderPost.createOrReplace(fromRemotePost: remotePost, for: readerTopic, context: context)
                    // To keep the API order
                    post?.sortRank = NSNumber(value: Date().timeIntervalSinceReferenceDate - Double(((self.pageNumber * Constants.paginationMultiplier) + index)))
                }

                // Clean up
                let service = ReaderPostService(coreDataStack: self.coreDataStack)
                service.deletePostsInExcessOfMaxAllowed(for: readerTopic)
                service.deletePostsFromBlockedSites()
            }, completion: {
                let hasMore = pageHandle != nil
                success(posts.count, hasMore)
            }, on: .main)
        }, failure: { error in
            failure(error)
        })
    }

    private func removePosts(forTopic topic: ReaderAbstractTopic, in context: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderPost.classNameWithoutNamespaces())
        fetchRequest.predicate = NSPredicate(format: "topic == %@", argumentArray: [topic])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sortRank", ascending: false)]
        fetchRequest.returnsObjectsAsFaults = false

        do {
            let results = try context.fetch(fetchRequest)
            for object in results {
                // do not delete if the post is displayed somewhere or saved by the user.
                // the content and all the metadata should be updated correctly later while preserving
                // `inUse` and `isSavedForLater`.
                guard let post = object as? ReaderPost,
                      !post.inUse,
                      !post.isSavedForLater else {
                    continue
                }
                context.delete(post)
            }
        } catch let error {
            print("Clean post error:", error)
        }
    }

    private enum Constants {
        static let paginationMultiplier = 100
    }
}
