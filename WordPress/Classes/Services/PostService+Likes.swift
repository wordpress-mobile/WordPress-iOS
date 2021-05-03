extension PostService {

    /**
     Fetches a list of users that liked the post with the given ID.
     
     @param postID  The ID of the post to fetch likes for
     @param siteID  The ID of the site that contains the post
     @param success A success block
     @param failure A failure block
     */
    func getLikesFor(postID: NSNumber,
                     siteID: NSNumber,
                     success: @escaping (([LikeUser]) -> Void),
                     failure: @escaping ((Error?) -> Void)) {

        guard let remote = PostServiceRemoteFactory().restRemoteFor(siteID: siteID, context: managedObjectContext) else {
            DDLogError("Unable to create a REST remote for posts.")
            failure(nil)
            return
        }

        remote.getLikesForPostID(postID) { remoteLikeUsers in
            self.createNewUsers(from: remoteLikeUsers, postID: postID, siteID: siteID) {
                let users = self.likeUsersFor(postID: postID, siteID: siteID)
                success(users)
            }
        } failure: { error in
            DDLogError(String(describing: error))
            failure(error)
        }
    }

}

private extension PostService {

    func createNewUsers(from remoteLikeUsers: [RemoteLikeUser]?,
                        postID: NSNumber,
                        siteID: NSNumber,
                        onComplete: @escaping (() -> Void)) {

        guard let remoteLikeUsers = remoteLikeUsers,
              !remoteLikeUsers.isEmpty else {
            onComplete()
            return
        }

        let derivedContext = ContextManager.shared.newDerivedContext()

        derivedContext.perform {

            self.deleteExistingUsersFor(postID: postID, siteID: siteID, from: derivedContext)

            remoteLikeUsers.forEach {
                LikeUserHelper.createUserFrom(remoteUser: $0, context: derivedContext)
            }

            ContextManager.shared.save(derivedContext) {
                DispatchQueue.main.async {
                    onComplete()
                }
            }
        }
    }

    func deleteExistingUsersFor(postID: NSNumber, siteID: NSNumber, from context: NSManagedObjectContext) {
        let request = LikeUser.fetchRequest() as NSFetchRequest<LikeUser>
        request.predicate = NSPredicate(format: "likedSiteID = %@ AND likedPostID = %@", siteID, postID)

        do {
            let users = try context.fetch(request)
            users.forEach { context.delete($0) }
        } catch {
            DDLogError("Error fetching post Like Users: \(error)")
        }
    }

    func likeUsersFor(postID: NSNumber, siteID: NSNumber) -> [LikeUser] {
        let request = LikeUser.fetchRequest() as NSFetchRequest<LikeUser>
        request.predicate = NSPredicate(format: "likedSiteID = %@ AND likedPostID = %@", siteID, postID)
        request.sortDescriptors = [NSSortDescriptor(key: "dateLiked", ascending: false)]

        if let users = try? managedObjectContext.fetch(request) {
            return users
        }

        return [LikeUser]()
    }

}
