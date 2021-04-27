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
                     success: @escaping (([LikeUser]?) -> Void),
                     failure: ((Error?) -> Void)? = nil) {

        guard let remote = PostServiceRemoteFactory().restRemoteFor(siteID: siteID, context: managedObjectContext) else {
            DDLogError("Unable to create a REST remote for posts.")
            failure?(nil)
            return
        }

        remote.getLikesForPostID(postID) { remoteLikeUsers in

            self.deleteExistingUsersFor(postID: postID)

            guard let remoteLikeUsers = remoteLikeUsers,
                  !remoteLikeUsers.isEmpty else {
                success(nil)
                return
            }

            success(self.createNewUsers(from: remoteLikeUsers))
        } failure: { error in
            DDLogError(String(describing: error))
            failure?(error)
        }
    }

}

private extension PostService {

    private func createNewUsers(from remoteLikeUsers: [RemoteLikeUser]) -> [LikeUser] {
        var likeUsers = [LikeUser]()

        remoteLikeUsers.forEach {
            if let likeUser = LikeUserHelper.createUserFrom(remoteUser: $0, context: self.managedObjectContext) {
                likeUsers.append(likeUser)
            }
        }

        return likeUsers
    }

    private func deleteExistingUsersFor(postID: NSNumber) {
        let request = LikeUser.fetchRequest() as NSFetchRequest<LikeUser>

        // TODO: filter by postID

        do {
            let users = try managedObjectContext.fetch(request)
            users.forEach { managedObjectContext.delete($0) }
        } catch {
            DDLogError("Error fetching Like Users: \(error)")
        }
    }

}
