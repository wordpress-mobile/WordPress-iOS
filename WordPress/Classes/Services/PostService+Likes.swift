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
            self.createNewUsers(from: remoteLikeUsers, for: postID) {
                let users = self.likeUsersFor(postID: postID)
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
                        for postID: NSNumber,
                        onComplete: @escaping (() -> Void)) {

        guard let remoteLikeUsers = remoteLikeUsers,
              !remoteLikeUsers.isEmpty else {
            onComplete()
            return
        }

        let derivedContext = ContextManager.shared.newDerivedContext()

        derivedContext.perform {

            self.deleteExistingUsersFor(postID: postID, from: derivedContext)

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

    func deleteExistingUsersFor(postID: NSNumber, from context: NSManagedObjectContext) {
        let request = LikeUser.fetchRequest() as NSFetchRequest<LikeUser>

        // TODO: filter request by postID

        do {
            let users = try context.fetch(request)
            users.forEach { context.delete($0) }
        } catch {
            DDLogError("Error fetching Like Users: \(error)")
        }
    }

    func likeUsersFor(postID: NSNumber) -> [LikeUser] {
        let request = LikeUser.fetchRequest() as NSFetchRequest<LikeUser>

        // TODO: filter request by postID

        if let users = try? managedObjectContext.fetch(request) {
            return users
        }

        return [LikeUser]()
    }

}
