extension PostService {

    /**
     Fetches a list of users from remote that liked the post with the given IDs.
     
     @param postID          The ID of the post to fetch likes for
     @param siteID          The ID of the site that contains the post
     @param count           Number of records to retrieve. Optional. Defaults to the endpoint max of 90.
     @param before          Filter results to likes before this date/time. Optional.
     @param excludingIDs    An array of user IDs to exclude from the returned results. Optional.
     @param purgeExisting   Indicates if existing Likes for the given post and site should be purged before
                            new ones are created. Defaults to true.
     @param success         A success block returning:
                            - Array of LikeUser
                            - Total number of likes for the given post
                            - Number of likes per fetch
     @param failure         A failure block
     */
    func getLikesFor(postID: NSNumber,
                     siteID: NSNumber,
                     count: Int = 90,
                     before: String? = nil,
                     excludingIDs: [NSNumber]? = nil,
                     purgeExisting: Bool = true,
                     success: @escaping (([LikeUser], Int, Int) -> Void),
                     failure: @escaping ((Error?) -> Void)) {

        guard let remote = postServiceRemoteFactory.restRemoteFor(siteID: siteID, context: managedObjectContext) else {
            DDLogError("Unable to create a REST remote for posts.")
            failure(nil)
            return
        }

        remote.getLikesForPostID(postID,
                                 count: NSNumber(value: count),
                                 before: before,
                                 excludeUserIDs: excludingIDs,
                                 success: { remoteLikeUsers, totalLikes in
                                    self.createNewUsers(from: remoteLikeUsers,
                                                        postID: postID,
                                                        siteID: siteID,
                                                        purgeExisting: purgeExisting) {
                                        let users = self.likeUsersFor(postID: postID, siteID: siteID)
                                        success(users, totalLikes.intValue, count)
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
     @param after   Filter results to likes after this Date.
     */
    func likeUsersFor(postID: NSNumber, siteID: NSNumber, after: Date? = nil) -> [LikeUser] {
        let request = LikeUser.fetchRequest() as NSFetchRequest<LikeUser>

        request.predicate = {
            if let after = after {
                // The date comparison is 'less than' because Likes are in descending order.
                return NSPredicate(format: "likedSiteID = %@ AND likedPostID = %@ AND dateLiked < %@", siteID, postID, after as CVarArg)
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

            let likers = remoteLikeUsers.map { remoteUser in
                LikeUserHelper.createOrUpdateFrom(remoteUser: remoteUser, context: derivedContext)
            }

            if purgeExisting {
                self.deleteExistingUsersFor(postID: postID, siteID: siteID, from: derivedContext, likesToKeep: likers)
            }

            ContextManager.shared.save(derivedContext) {
                DispatchQueue.main.async {
                    onComplete()
                }
            }
        }
    }

    func deleteExistingUsersFor(postID: NSNumber, siteID: NSNumber, from context: NSManagedObjectContext, likesToKeep: [LikeUser]) {
        let request = LikeUser.fetchRequest() as NSFetchRequest<LikeUser>
        request.predicate = NSPredicate(format: "likedSiteID = %@ AND likedPostID = %@ AND NOT (self IN %@)", siteID, postID, likesToKeep)

        do {
            let users = try context.fetch(request)
            users.forEach { context.delete($0) }
        } catch {
            DDLogError("Error fetching post Like Users: \(error)")
        }
    }

}
