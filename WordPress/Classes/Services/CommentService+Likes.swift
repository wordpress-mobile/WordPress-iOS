extension CommentService {

    /**
     Fetches a list of users that liked the comment with the given ID.
     
     @param commentID  The ID of the comment to fetch likes for
     @param siteID     The ID of the site that contains the post
     @param success    A success block
     @param failure    A failure block
     */
    func getLikesFor(commentID: NSNumber,
                     siteID: NSNumber,
                     success: @escaping (([LikeUser]) -> Void),
                     failure: @escaping ((Error?) -> Void)) {

        guard let remote = restRemote(forSite: siteID) else {
            DDLogError("Unable to create a REST remote for comments.")
            failure(nil)
            return
        }

        remote.getLikesForCommentID(commentID) { remoteLikeUsers in
            self.createNewUsers(from: remoteLikeUsers, commentID: commentID, siteID: siteID) {
                let users = self.likeUsersFor(commentID: commentID, siteID: siteID)
                success(users)
            }
        } failure: { error in
            DDLogError(String(describing: error))
            failure(error)
        }
    }

}

private extension CommentService {

    func createNewUsers(from remoteLikeUsers: [RemoteLikeUser]?,
                        commentID: NSNumber,
                        siteID: NSNumber,
                        onComplete: @escaping (() -> Void)) {

        guard let remoteLikeUsers = remoteLikeUsers,
              !remoteLikeUsers.isEmpty else {
            onComplete()
            return
        }

        let derivedContext = ContextManager.shared.newDerivedContext()

        derivedContext.perform {

            self.deleteExistingUsersFor(commentID: commentID, siteID: siteID, from: derivedContext)

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

    func deleteExistingUsersFor(commentID: NSNumber, siteID: NSNumber, from context: NSManagedObjectContext) {
        let request = LikeUser.fetchRequest() as NSFetchRequest<LikeUser>
        request.predicate = NSPredicate(format: "likedSiteID = %@ AND likedCommentID = %@", siteID, commentID)

        do {
            let users = try context.fetch(request)
            users.forEach { context.delete($0) }
        } catch {
            DDLogError("Error fetching comment Like Users: \(error)")
        }
    }

    func likeUsersFor(commentID: NSNumber, siteID: NSNumber) -> [LikeUser] {
        let request = LikeUser.fetchRequest() as NSFetchRequest<LikeUser>
        request.predicate = NSPredicate(format: "likedSiteID = %@ AND likedCommentID = %@", siteID, commentID)
        request.sortDescriptors = [NSSortDescriptor(key: "dateLiked", ascending: false)]

        if let users = try? managedObjectContext.fetch(request) {
            return users
        }

        return [LikeUser]()
    }

}
