import Foundation

extension ReaderPostService {
    func fetchPostsV2(for topic: ReaderTagTopic, isFirstPage: Bool = true, success: @escaping (Int, Bool) -> Void, failure: @escaping (Error?) -> Void) {
        if isFirstPage {
            nextPageHandle = nil
        }

        let remoteService = ReaderPostServiceRemote.withDefaultApi()
        remoteService.fetchPosts(for: [topic.slug], page: nextPageHandle, success: { [weak self] posts, pageHandle in
            guard let self = self else {
                return
            }

            self.managedObjectContext.perform {

                if self.managedObjectContext.parent == ContextManager.shared.mainContext {
                    // Its possible the ReaderAbstractTopic was deleted the parent main context.
                    // If so, and we merge and save, it will cause a crash.
                    // Reset the context so it will be current with its parent context.
                    self.managedObjectContext.reset()
                }

                guard let readerTopic = try? self.managedObjectContext.existingObject(with: topic.objectID) as? ReaderAbstractTopic else {
                    // if there was an error or the topic was deleted just bail.
                    success(0, false)
                    return
                }

                self.nextPageHandle = pageHandle

                if isFirstPage {
                    self.pageNumber = 1
                    self.removePosts(forTopic: readerTopic)
                } else {
                    self.pageNumber += 1
                }

                posts.enumerated().forEach { index, remotePost in
                    let post = ReaderPost.createOrReplace(fromRemotePost: remotePost, for: readerTopic, context: self.managedObjectContext)
                    // To keep the API order
                    post?.sortRank = NSNumber(value: Date().timeIntervalSinceReferenceDate - Double(((self.pageNumber * Constants.paginationMultiplier) + index)))
                }

                // Clean up
                self.deletePostsInExcessOfMaxAllowed(for: readerTopic)
                self.deletePostsFromBlockedSites()

                ContextManager.shared.save(self.managedObjectContext) {
                    let hasMore = pageHandle != nil
                    success(posts.count, hasMore)
                }

            }

        }, failure: { error in
            failure(error)
        })
    }

    private func removePosts(forTopic topic: ReaderAbstractTopic) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderPost.classNameWithoutNamespaces())
        fetchRequest.predicate = NSPredicate(format: "topic == %@", argumentArray: [topic])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sortRank", ascending: false)]
        fetchRequest.returnsObjectsAsFaults = false

        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            for object in results {
                guard let objectData = object as? NSManagedObject else { continue }
                managedObjectContext.delete(objectData)

                // Checar se ta em uso ou foi salvo
            }
        } catch let error {
            print("Clean post error:", error)
        }
    }

    private enum Constants {
        static let paginationMultiplier = 100
    }
}
