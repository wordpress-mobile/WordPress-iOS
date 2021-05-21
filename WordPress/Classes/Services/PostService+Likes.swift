extension PostService {

    /**
     Fetches a list of users from remote that liked the post with the given IDs.
     
     @param postID          The ID of the post to fetch likes for
     @param siteID          The ID of the site that contains the post
     @param count           Number of records to retrieve. Optional. Defaults to the endpoint max of 90.
     @param before          Filter results to likes before this date/time. Optional.
     @param purgeExisting   Indicates if existing Likes for the given post and site should be purged before
                            new ones are created. Defaults to false.
     @param success         A success block
     @param failure         A failure block
     */
    func getLikesFor(postID: NSNumber,
                     siteID: NSNumber,
                     count: Int = 90,
                     before: String? = nil,
                     purgeExisting: Bool = false,
                     success: @escaping (([LikeUser], Int) -> Void),
                     failure: @escaping ((Error?) -> Void)) {

        guard let remote = postServiceRemoteFactory.restRemoteFor(siteID: siteID, context: managedObjectContext) else {
            DDLogError("Unable to create a REST remote for posts.")
            failure(nil)
            return
        }

        remote.getLikesForPostID(postID,
                                 count: NSNumber(value: count),
                                 before: before,
                                 success: { remoteLikeUsers, totalLikes in
                                    self.createNewUsers(from: remoteLikeUsers,
                                                        postID: postID,
                                                        siteID: siteID,
                                                        purgeExisting: purgeExisting) {
                                        let users = self.likeUsersFor(postID: postID, siteID: siteID, before: before)
                                        success(users, totalLikes.intValue)
                                        LikeUserHelper.purgeStaleLikes()
                                    }
                                 }, failure: { error in
                                    DDLogError(String(describing: error))
                                    failure(error)
                                 })
    }

    /**
     Fetches a list of users from Core Data that liked the post with the given IDs.
     
     @param postID  The ID of the post to fetch likes for.
     @param siteID  The ID of the site that contains the post.
     @param before  Filter results to likes before this date/time. Optional.
     */
    func likeUsersFor(postID: NSNumber, siteID: NSNumber, before: String? = nil) -> [LikeUser] {
        let request = LikeUser.fetchRequest() as NSFetchRequest<LikeUser>

        request.predicate = {
            if let beforeDate = DateUtils.date(fromISOString: before) {
                return NSPredicate(format: "likedSiteID = %@ AND likedPostID = %@ AND dateLiked < %@", siteID, postID, beforeDate as CVarArg)
            }

            return NSPredicate(format: "likedSiteID = %@ AND likedPostID = %@", siteID, postID)
        }()

        request.sortDescriptors = [NSSortDescriptor(key: "dateLiked", ascending: false)]

        if let users = try? managedObjectContext.fetch(request) {
            return users
        }

        return [LikeUser]()
    }

}

private extension PostService {

    func createNewUsers(from remoteLikeUsers: [RemoteLikeUser]?,
                        postID: NSNumber,
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
                self.deleteExistingUsersFor(postID: postID, siteID: siteID, from: derivedContext)
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

}
