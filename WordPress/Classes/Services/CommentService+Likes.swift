extension CommentService {

    /**
     Fetches a list of users from remote that liked the comment with the given IDs.
     
     @param commentID       The ID of the comment to fetch likes for
     @param siteID          The ID of the site that contains the post
     @param count           Number of records to retrieve. Optional. Defaults to the endpoint max of 90.
     @param before          Filter results to likes before this date/time. Optional.
     @param excludingIDs    An array of user IDs to exclude from the returned results. Optional.
     @param purgeExisting   Indicates if existing Likes for the given post and site should be purged before
                            new ones are created. Defaults to true.
     @param success         A success block
     @param failure         A failure block
     */
    func getLikesFor(commentID: NSNumber,
                     siteID: NSNumber,
                     count: Int = 90,
                     before: String? = nil,
                     excludingIDs: [NSNumber]? = nil,
                     purgeExisting: Bool = true,
                     success: @escaping (([LikeUser], Int) -> Void),
                     failure: @escaping ((Error?) -> Void)) {

        guard let remote = restRemote(forSite: siteID) else {
            DDLogError("Unable to create a REST remote for comments.")
            failure(nil)
            return
        }

        remote.getLikesForCommentID(commentID,
                                    count: NSNumber(value: count),
                                    before: before,
                                    excludeUserIDs: excludingIDs,
                                    success: { remoteLikeUsers, totalLikes in
                                        self.createNewUsers(from: remoteLikeUsers,
                                                            commentID: commentID,
                                                            siteID: siteID,
                                                            purgeExisting: purgeExisting) {
                                            let users = self.likeUsersFor(commentID: commentID, siteID: siteID)
                                            success(users, totalLikes.intValue)
                                            LikeUserHelper.purgeStaleLikes()
                                        }
                                    }, failure: { error in
                                        DDLogError(String(describing: error))
                                        failure(error)
                                    })
    }

    /**
     Fetches a list of users from Core Data that liked the comment with the given IDs.
     
     @param commentID   The ID of the comment to fetch likes for.
     @param siteID      The ID of the site that contains the post.
     @param after       Filter results to likes after this Date. Optional.
     */
    func likeUsersFor(commentID: NSNumber, siteID: NSNumber, after: Date? = nil) -> [LikeUser] {
        let request = LikeUser.fetchRequest() as NSFetchRequest<LikeUser>

        request.predicate = {
            if let after = after {
                // The date comparison is 'less than' because Likes are in descending order.
                return NSPredicate(format: "likedSiteID = %@ AND likedCommentID = %@ AND dateLiked < %@", siteID, commentID, after as CVarArg)
            }

            return NSPredicate(format: "likedSiteID = %@ AND likedCommentID = %@", siteID, commentID)
        }()

        request.sortDescriptors = [NSSortDescriptor(key: "dateLiked", ascending: false)]

        if let users = try? managedObjectContext.fetch(request) {
            return users
        }

        return [LikeUser]()
    }

}

private extension CommentService {

    func createNewUsers(from remoteLikeUsers: [RemoteLikeUser]?,
                        commentID: NSNumber,
                        siteID: NSNumber,
                        purgeExisting: Bool,
                        onComplete: @escaping (() -> Void)) {

        guard let remoteLikeUsers = remoteLikeUsers,
              !remoteLikeUsers.isEmpty else {
            onComplete()
            return
        }

        let derivedContext = ContextManager.shared.newDerivedContext()

        derivedContext.perform {

            if purgeExisting {
                self.deleteExistingUsersFor(commentID: commentID, siteID: siteID, from: derivedContext)
            }

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

}
