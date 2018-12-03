import Foundation


extension PostService {

    /// PostService API to get the revisions list
    ///
    /// - Parameters:
    ///   - post: A valid abstract post
    ///   - success: The success block accepts an optional list of Revisions
    ///   - failure: The failure block accepts an optional error
    func getPostRevisions(for post: AbstractPost,
                          success: @escaping ([Revision]?) -> Void,
                          failure: @escaping (Error?) -> Void) {
        guard let blogId = post.blog.dotComID,
            let postId = post.postID,
            let api = post.blog.wordPressComRestApi() else {
                failure(nil)
                return
        }

        let remote = PostServiceRemoteREST(wordPressComRestApi: api, siteID: blogId)
        remote.getPostRevisions(for: blogId.intValue,
                                postId: postId.intValue,
                                success: { (remoteRevisions) in
                                    self.managedObjectContext.perform {
                                        let revisions = self.syncPostRevisions(from: remoteRevisions ?? [],
                                                                               for: postId.intValue,
                                                                               with: blogId.intValue)
                                        ContextManager.sharedInstance().save(self.managedObjectContext, withCompletionBlock: {
                                            success(revisions)
                                        })
                                    }
        }, failure: failure)
    }


    // MARK: Private methods

    private func syncPostRevisions(from remoteRevisions: [RemoteRevision],
                                   for postId: Int,
                                   with siteId: Int) -> [Revision] {
        return remoteRevisions.map { mapRevision(from: $0, for: postId, with: siteId) }
    }

    private func mapRevision(from remoteRevision: RemoteRevision,
                             for postId: Int,
                             with siteId: Int) -> Revision {
        let siteId = NSNumber(value: siteId)
        let revisionId = NSNumber(value: remoteRevision.id)
        let revision = findPostRevision(with: revisionId, and: siteId)
        revision.revisionId = revisionId
        revision.siteId = siteId
        revision.postId = NSNumber(value: postId)

        if let postAuthorId = remoteRevision.postAuthorId,
            let postAuthorIdAsInt = Int(postAuthorId) {
            revision.postAuthorId = NSNumber(value: postAuthorIdAsInt)
        } else {
            revision.postAuthorId = nil
        }

        revision.postTitle = remoteRevision.postTitle
        revision.postContent = remoteRevision.postContent
        revision.postExcerpt = remoteRevision.postExcerpt

        revision.postDateGmt = remoteRevision.postDateGmt
        revision.postModifiedGmt = remoteRevision.postModifiedGmt

        revision.diff = mapRevisionDiff(from: remoteRevision, for: revision)

        return revision
    }

    private func mapRevisionDiff(from remoteRevision: RemoteRevision,
                                 for revision: Revision) -> RevisionDiff? {
        guard let diff = remoteRevision.diff else {
            return nil
        }

        let revisionDiff = findDiff(for: revision)
        revisionDiff.fromRevisionId = NSNumber(value: diff.fromRevisionId)
        revisionDiff.toRevisionId = NSNumber(value: diff.toRevisionId)

        revisionDiff.totalAdditions = NSNumber(value: diff.values.totals?.totalAdditions ?? 0)
        revisionDiff.totalDeletions = NSNumber(value: diff.values.totals?.totalDeletions ?? 0)

        revisionDiff.remove(DiffContentValue.self).add(values: diff.values.contentDiffs) {
            return self.diffValue(for: DiffContentValue.self, with: $1, at: $0)
        }

        revisionDiff.remove(DiffTitleValue.self).add(values: diff.values.titleDiffs) {
            return self.diffValue(for: DiffTitleValue.self, with: $1, at: $0)
        }

        return revisionDiff
    }

    private func findPostRevision(with revisionId: NSNumber, and siteId: NSNumber) -> Revision {
        return managedObjectContext.entity(of: Revision.self,
                                           with: NSPredicate(format: "\(#keyPath(Revision.revisionId)) = %@ AND \(#keyPath(Revision.siteId)) = %@", revisionId, siteId))
    }

    private func findDiff(for revision: Revision) -> RevisionDiff {
        return managedObjectContext.entity(of: RevisionDiff.self,
                                           with: NSPredicate(format: "\(#keyPath(RevisionDiff.revision)) = %@", revision))
    }

    private func diffValue<Value: DiffAbstractValue>(for type: Value.Type, with remoteValue: RemoteDiffValue, at index: Int) -> Value {
        let diffValue = managedObjectContext.insertNewObject(ofType: type)
        diffValue.operation = DiffContentValue.Operation(rawValue: remoteValue.operation.rawValue) ?? .unknown
        diffValue.type = type is DiffTitleValue.Type ? .title : .content
        diffValue.value = remoteValue.value
        diffValue.index = index
        return diffValue
    }
}
