import Foundation
import WordPressKit
import CoreData

extension PostHelper {
    @objc(updatePost:withRemotePost:inContext:)
    static func update(_ post: AbstractPost, with remotePost: RemotePost, in context: NSManagedObjectContext) {
        let previousPostID = post.postID
        updateIfNeeded(post, \.postID, remotePost.postID)

        // Used to populate author information for self-hosted sites.
        let author = post.blog.getAuthorWith(id: remotePost.authorID)
        updateIfNeeded(post, \.author, remotePost.authorDisplayName ?? author?.displayName)
        updateIfNeeded(post, \.authorID, remotePost.authorID)
        updateIfNeeded(post, \.date_created_gmt, remotePost.date)
        updateIfNeeded(post, \.dateModified, remotePost.dateModified)


        updateIfNeeded(post, \.postTitle, remotePost.title)
        updateIfNeeded(post, \.permaLink, remotePost.url.absoluteString)
        updateIfNeeded(post, \.content, remotePost.content)
        updateIfNeeded(post, \.statusString, remotePost.status)
        updateIfNeeded(post, \.password, remotePost.password)

        if let postThumbnailID = remotePost.postThumbnailID {
            let media = Media.existingOrStubMediaWith(mediaID: postThumbnailID, inBlog: post.blog)
            updateIfNeeded(post, \.featuredImage, media)
        } else {
            updateIfNeeded(post, \.featuredImage, nil)
        }
        updateIfNeeded(post, \.pathForDisplayImage, remotePost.pathForDisplayImage)
        if post.pathForDisplayImage?.isEmpty ?? true {
            post.updatePathForDisplayImageBasedOnContent()
        }

        updateIfNeeded(post, \.authorAvatarURL, remotePost.authorAvatarURL ?? author?.avatarURL)
        updateIfNeeded(post, \.mt_excerpt, remotePost.excerpt)
        updateIfNeeded(post, \.wp_slug, remotePost.slug)
        updateIfNeeded(post, \.suggested_slug, remotePost.suggestedSlug)

        let currentRevisions = post.revisions as? [NSNumber]
        let newRevisions = remotePost.revisions as? [NSNumber]
        if newRevisions != currentRevisions {
            post.revisions = newRevisions
        }
        if remotePost.postID != previousPostID {
            PostHelper.updateComments(for: post)
        }

        let autosave = remotePost.autosave
        updateIfNeeded(post, \.autosaveTitle, autosave?.title)
        updateIfNeeded(post, \.autosaveExcerpt, autosave?.excerpt)
        updateIfNeeded(post, \.autosaveContent, autosave?.content)
        updateIfNeeded(post, \.autosaveModifiedDate, autosave?.modifiedDate)
        updateIfNeeded(post, \.autosaveIdentifier, autosave?.identifier)

        switch post {
        case let page as Page:
            updateIfNeeded(page, \.parentID, remotePost.parentID)
        case let post as Post:
            updateIfNeeded(post, \.statusAfterSyncString, remotePost.status)
            updateIfNeeded(post, \.commentCount, remotePost.commentCount)
            updateIfNeeded(post, \.likeCount, remotePost.likeCount)
            updateIfNeeded(post, \.postFormat, remotePost.format)
            updateIfNeeded(post, \.tags, (remotePost.tags as? [String])?.joined(separator: ","))
            updateIfNeeded(post, \.postType, remotePost.type)
            updateIfNeeded(post, \.isStickyPost, (remotePost.isStickyPost != nil ? remotePost.isStickyPost.boolValue : false))
            PostHelper.update(post, withRemoteCategories: remotePost.categories, in: context)

            let publicizeInfo = PostHelper.makePublicizeInfo(with: post, remotePost: remotePost)
            updateIfNeeded(post, \.publicID, publicizeInfo.publicID)
            updateIfNeeded(post, \.publicizeMessage, publicizeInfo.publicizeMessage)
            updateIfNeeded(post, \.publicizeMessageID, publicizeInfo.publicizeMessageID)
            updateIfNeeded(post, \.disabledPublicizeConnections, publicizeInfo.disabledPublicizeConnections)
        default:
            break
        }
    }
}

private func updateIfNeeded<T, U: Equatable>(_ object: T, _ path: ReferenceWritableKeyPath<T, U>, _ newValue: U) {
    if object[keyPath: path] != newValue {
        object[keyPath: path] = newValue
    }
}
