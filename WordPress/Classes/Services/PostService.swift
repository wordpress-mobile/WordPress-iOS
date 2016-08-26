import Foundation

// manages the creation, saving, updating, and merging of Posts, Pages, and associated data such as comments
class PostService : LocalCoreDataService {
    static let ErrorDomain = "PostServiceErrorDomain"
    static let DefaultNumberToSync: UInt = 40

    enum PostType: String {
        case any = "any"
        case post = "post"
        case page = "page"

        func type() -> AbstractPost.Type {
            switch self {
            case .post: return Post.self
            case .page: return Page.self
            case .any: return AbstractPost.self
            }
        }
    }

    typealias SuccessPosts = ([AbstractPost]) -> Void
    typealias FailureBasic = (NSError?) -> Void
    typealias SuccessBasic = () -> Void

    convenience override init() {
        self.init(managedObjectContext: ContextManager.sharedInstance().mainContext)
    }

    func makePost(for blog: Blog) -> Post? {
        return make(type: Post.self, blog: blog)
    }

    func makePage(for blog: Blog) -> Page? {
        return make(type: Page.self, blog: blog)
    }

    func make(postType: PostType?, blog: Blog) -> AbstractPost? {
        return make(type: postType?.type() ?? Post.self, blog: blog)
    }

    func make<T: AbstractPost>(type postType: T.Type, blog: Blog) -> T? {
        assert(self.managedObjectContext == blog.managedObjectContext, "Blog's context should be the the same as the service's")

        guard let post = NSEntityDescription.insertNewObjectForEntityForName(postType.entityName(), inManagedObjectContext: self.managedObjectContext) as? T else {
            return nil
        }

        post.blog = blog
        post.remoteStatus = AbstractPostRemoteStatusSync

        guard let postPost = post as? Post else {
            return post
        }

        postPost.postFormat = blog.settings?.defaultPostFormat
        postPost.postType = Post.typeDefaultIdentifier

        let postCategoryService = PostCategoryService(managedObjectContext:self.managedObjectContext)
        if let category = postCategoryService.findWithBlogObjectID(blog.objectID, andCategoryID: (blog.settings?.defaultCategoryID)!) {
            postPost.addCategoriesObject(category)
        }

        return postPost as? T
    }

    func makeDraftPost(for blog: Blog) -> Post? {
        guard let post = self.makePost(for: blog) else { return nil }
        post.remoteStatus = AbstractPostRemoteStatusLocal
        return post
    }

    func makeDraftPage(for blog: Blog) -> Page? {
        guard let page = self.makePage(for: blog) else { return nil }
        page.remoteStatus = AbstractPostRemoteStatusLocal
        return page
    }

    /**
     Sync a specific post from the API

     - parameters:
        - postID: The ID of the post to sync
        - blog: The blog that has the post
        - success: A success block
        - failure: A failure block
     */
    func get(postID: Int, blog: Blog, success: (AbstractPost?) -> Void, failure: ((NSError?) -> Void)?) {
        if let remote = self.remote(for:blog) {
            let blogID = blog.objectID
            remote.getPostWithID(postID,
                                 success: { (remotePost: RemotePost?) -> Void in
                                    self.managedObjectContext.performBlock({
                                        guard let blogInContext = (try? self.managedObjectContext.existingObjectWithID(blogID)) as? Blog else { return }

                                        guard let remotePost = remotePost else {
                                            if let failure = failure {
                                                let userInfo = [NSLocalizedDescriptionKey: "Retrieved remote post is nil"]
                                                failure(NSError(domain: ReaderPostServiceErrorDomain, code: 0, userInfo: userInfo))
                                            }
                                            return
                                        }

                                        let post = self.find(byID: postID, blog: blogInContext) ?? self.makePost(for: blogInContext)

                                        if let post = post {
                                            self.update(post, with:remotePost)
                                        }
                                        ContextManager.sharedInstance().saveContext(self.managedObjectContext)

                                        success(post)
                                    })
                },
                                 failure: { (error: NSError?) in
                                    if let failure = failure {
                                        self.managedObjectContext.performBlock({
                                            failure(error)
                                        })
                                    }
                }
            )
        }
    }

    /**
     Sync an initial batch of posts from the specified blog.

     - note: Please note that success and/or failure are called in the context of the
     NSManagedObjectContext supplied when the PostService was initialized, and may not
     run on the main thread.

     - parameters:
         - postType: The type (post or page) of post to sync
         - blog: The blog that has the posts.
         - success: åA success block
         - failure: A failure block
     */
    func sync(type: PostType, blog: Blog, success: SuccessPosts, failure: FailureBasic) {
        self.sync(type, blog: blog, options: nil, success: success, failure: failure)
    }

    /**
     Sync a batch of posts with the specified options from the specified blog.

     - note: Please note that success and/or failure are called in the context of the
     NSManagedObjectContext supplied when the PostService was initialized, and may not
     run on the main thread.

     - parameters:
         - postType: The type (post or page) of post to sync
         - options: Sync options for specific request parameters.
         - blog: The blog that has the posts.
         - success: A success block
         - failure: A failure block
    */
    func sync(type: PostType, blog: Blog, options: PostServiceSyncOptions?, success: SuccessPosts?, failure: FailureBasic?) {
        if let remote = self.remote(for:blog) {
            let blogID = blog.objectID
            let remoteOptions = self.remoteSyncParameters(for:remote, with:options)
            remote.getPostsOfType(type.rawValue, options: remoteOptions, success: { (remotePosts) in
                    self.managedObjectContext.performBlock({
                        do {
                            if let blogInContext = try self.managedObjectContext.existingObjectWithID(blogID) as? Blog {
                                self.merge(posts: remotePosts,
                                    type: type,
                                    statuses: options?.statuses,
                                    author: options?.authorID,
                                    blog: blogInContext,
                                    purge: options?.purgesLocalSync,
                                    completion: { posts in
                                        if let success = success {
                                            success(posts)
                                        }
                                })
                            }
                        } catch let error as NSError? {
                            DDLogSwift.logError(String("Could not retrieve blog in context with error: %@", error))
                        }
                    })
                }, failure: { (error) in
                    self.managedObjectContext.performBlock({
                        if let failure = failure {
                            failure(error)
                        }
                    })
            })
        }
    }
    /**
     Syncs local changes on a post back to the server.

     - parameters:
        - post: The post or page to upload
         - success: A success block.  If the post object exists locally (in CoreData) when the upload
         succeeds, then this block will also return a pointer to the updated local AbstractPost
         object.  It's important to note this object may not be the same one as the `post` input
         parameter, since if the input post was a revision, it will no longer exist once the upload
         succeeds.
         - failure: A failure block
     */
    func upload(post: AbstractPost, success: (AbstractPost?) -> Void, failure: (NSError?) -> Void) {
        let remote = self.remote(for: post.blog)
        let remotePost = self.getRemotePost(withPost: post)
        post.remoteStatus = AbstractPostRemoteStatusPushing
        ContextManager.sharedInstance().saveContext(self.managedObjectContext)
        let postObjectID = post.objectID
        let successBlock: (RemotePost!) -> Void = { post in
            self.managedObjectContext.performBlock({
                if var postInContext = (try? self.managedObjectContext.existingObjectWithID(postObjectID)) as? AbstractPost {
                    if let originalPost = postInContext.original where postInContext.isRevision() {
                        originalPost.applyRevision()
                        originalPost.deleteRevision()
                        postInContext = originalPost
                    }

                    self.update(postInContext, with: post)
                    postInContext.remoteStatus = AbstractPostRemoteStatusSync
                    let mediaService = MediaService(managedObjectContext: self.managedObjectContext)
                    for case let media as Media in postInContext.media where media.postID.longLongValue <= 0 {
                        media.postID = post.postID
                        mediaService.updateMedia(media, success: nil, failure: nil)
                    }
                    ContextManager.sharedInstance().saveContext(self.managedObjectContext)

                    success(postInContext)

                } else {
                    success(nil)
                }
            })
        }

        let failureBlock: (NSError?) -> Void = { error in
            self.managedObjectContext.performBlock({
                if let postInContext = (try? self.managedObjectContext.existingObjectWithID(postObjectID)) as? AbstractPost {
                    postInContext.remoteStatus = AbstractPostRemoteStatusFailed
                    ContextManager.sharedInstance().saveContext(self.managedObjectContext)
                }
                failure(error)
            })
        }

        if post.postID?.longLongValue > 0 {
            remote?.updatePost(remotePost, success: successBlock, failure: failureBlock)
        } else {
            remote?.createPost(remotePost, success: successBlock, failure: failureBlock)
        }
    }

    /**
     Attempts to delete the specified post outright vs moving it to the
     trash folder.

     - parameters:
         - post: The post or page to delete
         - success: A success block
         - failure: A failure block
     */
    func delete(post: AbstractPost, success: SuccessBasic, failure: FailureBasic) {

        let deleteBlock: SuccessBasic = {
            if let postID = post.postID where postID.longLongValue > 0 {
                let remotePost = self.getRemotePost(withPost: post)
                if let remote = self.remote(for: post.blog) {
                    remote.deletePost(remotePost, success: success, failure: failure)
                }
            }
        }

        if let original = post.original where post.isRevision() {
            self.delete(original, success: deleteBlock, failure: failure)
        } else {
            deleteBlock()
        }
    }

    /**
     Moves the specified post into the trash bin. Does not delete
     the post unless it was deleted on the server.

     - parameters:
         - post: The post or page to trash
         - success: A success block
         - failure: A failure block
     */
    func trash(post: AbstractPost, success: SuccessBasic, failure: FailureBasic) {
        if post.status == PostStatusTrash {
            self.delete(post, success: success, failure: failure)
            return
        }

        let trashBlock: SuccessBasic = {
            if let status = post.status {
                post.restorableStatus = status
            }
            if let postID = post.postID where postID.longLongValue <= 0  {
                post.status = PostStatusTrash

                success()

                return
            }

            self.trashRemotePost(withPost: post, success: success, failure: failure)
        }

        if post.isRevision() {
            self.trash(post, success: trashBlock, failure: failure)
        } else {
            trashBlock()
        }
    }

    func trashRemotePost(withPost post: AbstractPost, success: SuccessBasic, failure: FailureBasic) {
        let postObjectID = post.objectID
        let remotePost = self.getRemotePost(withPost: post)
        if let remote = self.remote(for: post.blog) {
            remote.trashPost(remotePost, success: { remotePost in
                    do {
                        if let postInContext = try self.managedObjectContext.existingObjectWithID(postObjectID) as? Post {
                            if remotePost.status == PostStatusDeleted {
                                self.managedObjectContext.deleteObject(postInContext)
                            } else {
                                self.update(postInContext, with: remotePost)
                            }
                            ContextManager.sharedInstance().saveContext(self.managedObjectContext)
                        }
                    } catch let error as NSError? {
                        DDLogSwift.logError(String("%@", error))
                    }
                    success()
                }, failure: { error in
                    do {
                        if let postInContext = try self.managedObjectContext.existingObjectWithID(postObjectID) as? Post {
                            postInContext.restorableStatus = nil
                        }
                    } catch let error as NSError? {
                        DDLogSwift.logError(String("%@", error))
                        failure(error)
                        return
                    }
                    failure(nil)
            })
        }
    }

    /**
     Moves the specified post out of the trash bin.

     - parameters:
        - post: The post or page to restore
        - success: A success block
        - failure: A failure block
     */
    func restore(post: AbstractPost, success: SuccessBasic, failure: FailureBasic) {
        let restoreBlock: SuccessBasic = {
            post.status = post.restorableStatus
            ContextManager.sharedInstance().saveContext(self.managedObjectContext)

            if !post.isRevision() && post.postID?.longLongValue > 0 {
                self.restoreRemotePost(withPost: post, success: success, failure: failure)
            } else {
                success()
            }
        }

        if let original = post.original where post.isRevision() {
            self.restore(original, success: restoreBlock, failure: failure)
        } else {
            restoreBlock()
        }
    }

    func restoreRemotePost(withPost post: AbstractPost, success: SuccessBasic, failure: FailureBasic) {
        let postObjectID = post.objectID
        let remotePost = self.getRemotePost(withPost: post)
        if let restorableStatus = post.restorableStatus {
            remotePost.status = restorableStatus
        } else {
            // Assign a status of draft to the remote post. The WordPress.com REST API will
            // ignore this and should restore the post's previous status. The XML-RPC API
            // needs a status assigned to move a post out of the trash folder. Draft is the
            // safest option when we don't know what the status was previously. - @aerych
            remotePost.status = PostStatusDraft
        }

        if let remote = self.remote(for: post.blog) {
            remote.restorePost(remotePost, success: { remotePost in
                do {
                    if let postInContext = try self.managedObjectContext.existingObjectWithID(postObjectID) as? Post {
                        postInContext.restorableStatus = nil
                        self.update(postInContext, with: remotePost)
                        ContextManager.sharedInstance().saveContext(self.managedObjectContext)
                    }
                } catch let error as NSError? {
                    DDLogSwift.logError(String("%@", error))
                }
                success()
            }, failure: { error in
                do {
                    if let postInContext = try self.managedObjectContext.existingObjectWithID(postObjectID) as? Post {
                        postInContext.status = PostStatusTrash
                        ContextManager.sharedInstance().saveContext(self.managedObjectContext)
                    }
                } catch let error as NSError? {
                    DDLogSwift.logError(String("%@", error))
                    failure(error)
                    return
                }
                failure(nil)
            })
        }
    }

    // MARK: - Helpers

    func initialize(draft post: AbstractPost) {
        post.remoteStatus = AbstractPostRemoteStatusLocal
    }

    func merge(posts remotePosts: [RemotePost], type: PostType, statuses: [String]?, author authorID: NSNumber?, blog: Blog, purge: Bool?, completion: ([AbstractPost]) -> Void) {
        let posts: [AbstractPost] = remotePosts.flatMap { remotePost in
            if let post = self.find(byID: remotePost.postID as Int, blog: blog) ?? self.make(PostType(rawValue:remotePost.type), blog: blog) {
                self.update(post, with: remotePost)
                return post
            }
            return nil
        }

        if let purge = purge where purge {
            var predicate = NSPredicate(format: "(remoteStatusNumber = %@) AND (postID != NULL) AND (original = NULL) AND (revision = NULL) AND (blog = %@)", NSNumber(unsignedInt: AbstractPostRemoteStatusSync.rawValue), blog)
            if let statuses = statuses where statuses.count > 0 {
                let statusPredicate = NSPredicate(format: "status IN %@", statuses)
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, statusPredicate])
            }
            if let authorID = authorID {
                let authorPredicate = NSPredicate(format: "authorID IN %@", [authorID])
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, authorPredicate])
            }

            let request = NSFetchRequest(entityName: type.type().entityName())
            if type == .post {
                let postTypePredicate = NSPredicate(format: "postType = %@", type.rawValue)
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, postTypePredicate])
            }
            request.predicate = predicate

            do {
                if let existingPosts = try self.managedObjectContext.executeFetchRequest(request) as? [AbstractPost] {
                    let postsToKeep = Set(posts)
                    let postsToDelete = Set(existingPosts).subtract(postsToKeep)
                    postsToDelete.forEach { post in
                        DDLogSwift.logInfo(NSString(format:"Deleting Post: %@", post) as String)
                        self.managedObjectContext.deleteObject(post)
                    }
                }
            } catch let error as NSError? {
                DDLogSwift.logError(String("Error fetching existing posts for purging: %@", error))
            }
        }

        ContextManager.sharedInstance().saveDerivedContext(self.managedObjectContext)
        completion(posts)
    }

    func find(byID postID: Int, blog: Blog) -> AbstractPost? {
        let request = NSFetchRequest(entityName: AbstractPost.entityName())
        request.predicate = NSPredicate(format: "blog = %@ AND original = NULL AND postID = %@", blog, postID as NSNumber)
        let posts = try! self.managedObjectContext.executeFetchRequest(request)
        return posts.first as? AbstractPost
    }

    func remoteSyncParameters(for remote: PostServiceRemote, with options: PostServiceSyncOptions?) -> [String: AnyObject]? {
        guard let options = options else {
            return nil
        }
        return remote.dictionaryWithRemoteOptions(options) as? [String : AnyObject]
    }

    func update(post: AbstractPost, with remotePost: RemotePost) {
        let previousPostID = post.postID
        post.postID = remotePost.postID
        post.author = remotePost.authorDisplayName
        post.authorID = remotePost.authorID
        post.date_created_gmt = remotePost.date
        post.dateModified = remotePost.dateModified
        post.postTitle = remotePost.title
        post.permaLink = remotePost.URL.absoluteString
        post.content = remotePost.content
        post.status = remotePost.status
        post.password = remotePost.password
        post.post_thumbnail = remotePost.postThumbnailID
        post.pathForDisplayImage = remotePost.pathForDisplayImage
        post.authorAvatarURL = remotePost.authorAvatarURL
        post.mt_excerpt = remotePost.excerpt

        if remotePost.postID != previousPostID {
            self.updateComments(for:post)
        }

        if let pagePost = post as? Page {
            pagePost.parentID = remotePost.parentID
        } else if let postPost = post as? Post {
            postPost.commentCount = remotePost.commentCount
            postPost.likeCount = remotePost.likeCount
            postPost.postFormat = remotePost.format
            postPost.tags = (remotePost.tags as! [String]).joinWithSeparator(",")
            postPost.postType = remotePost.type
            self.update(postPost, withRemoteCategories:remotePost.categories as? [RemotePostCategory])

            if let metadata = remotePost.metadata {
                if let latitudeDictionary = self.dictionary(with:"geo_latitude", in:metadata),
                let longitudeDictionary = self.dictionary(with:"geo_longitude", in:metadata),
                let geoPublicDictionary = self.dictionary(with:"geo_public", in:metadata) {
                    let latitude = Double(latitudeDictionary["value"] as! NSNumber)
                    let longitude = Double(longitudeDictionary["value"] as! NSNumber)
                    let coord = CLLocationCoordinate2DMake(latitude, longitude)
                    let geolocation = Coordinate(coordinate: coord)
                    postPost.geolocation = geolocation
                    postPost.latitudeID = latitudeDictionary["id"] as? String
                    postPost.longitudeID = longitudeDictionary["id"] as? String
                    postPost.publicID = geoPublicDictionary["id"] as? String
                }
            }
        }
    }

    func getRemotePost(withPost post: AbstractPost) -> RemotePost {
        let remotePost = RemotePost()
        remotePost.postID = post.postID
        remotePost.date = post.date_created_gmt
        remotePost.dateModified = post.dateModified
        remotePost.title = post.postTitle ?? ""
        remotePost.content = post.content
        remotePost.status = post.status
        remotePost.postThumbnailID = post.post_thumbnail
        remotePost.password = post.password
        remotePost.type = PostType.post.rawValue
        remotePost.authorAvatarURL = post.authorAvatarURL
        remotePost.isFeaturedImageChanged = post.isFeaturedImageChanged

        if let pagePost = post as? Page {
            remotePost.parentID = pagePost.parentID
            remotePost.type = PostType.page.rawValue
        } else if let postPost = post as? Post {
            remotePost.format = postPost.postFormat
            remotePost.tags = postPost.tags?.characters.split(",").map(String.init)
            remotePost.categories = self.remoteCategories(for:postPost)
        }

        return remotePost
    }

    func remoteCategories(for post: Post) -> [RemotePostCategory]? {
        return post.categories?.map { self.remoteCategory(with: $0) }
    }

    func remoteCategory(with category: PostCategory) -> RemotePostCategory {
        let remoteCategory = RemotePostCategory()
        remoteCategory.categoryID = category.categoryID
        remoteCategory.name = category.categoryName
        remoteCategory.parentID = category.parentID
        return remoteCategory
    }

    func remoteMetadata(for post: Post) -> [[String: AnyObject]] {
        var metadata: [[String: AnyObject]] = []
        let coordinate = post.geolocation

        /*
         This might look more complicated than it should be, but it needs to be that way. - @koke

         Depending of the existence of geolocation and ID values, we need to add/update/delete the custom fields:
         - geolocation  &&  ID: update
         - geolocation  && !ID: add
         - !geolocation &&  ID: delete
         - !geolocation && !ID: noop
         */

        if post.latitudeID != nil || coordinate != nil {
            var latitudeDictionary: [String: AnyObject] = [:]
            if let latitudeID = post.latitudeID {
                latitudeDictionary["id"] = latitudeID
            }
            if let c = coordinate {
                latitudeDictionary["key"] = "geo_latitude"
                latitudeDictionary["value"] = c.latitude
            }
            metadata.append(latitudeDictionary)
        }
        if post.longitudeID != nil || coordinate != nil {
            var longitudeDictionary: [String: AnyObject] = [:]
            if let longitudeID = post.longitudeID {
                longitudeDictionary["id"] = longitudeID
            }
            if let c = coordinate {
                longitudeDictionary["key"] = "geo_longitude"
                longitudeDictionary["value"] = c.longitude
            }
            metadata.append(longitudeDictionary)
        }
        if post.publicID != nil || coordinate != nil {
            var publicDictionary: [String: AnyObject] = [:]
            if let publicID = post.publicID {
                publicDictionary["id"] = publicID
            }
            if coordinate != nil {
                publicDictionary["key"] = "geo_public"
                publicDictionary["value"] = 1
            }
            metadata.append(publicDictionary)
        }
        return metadata
    }

    private func update(post: Post, withRemoteCategories remoteCategories: [RemotePostCategory]?) {
        guard let remoteCategories = remoteCategories else {
            // that this can be nil is a artifact of this file's Objective-C origin
            return
        }

        let blogObjectID = post.blog.objectID
        let categoryService = PostCategoryService(managedObjectContext:self.managedObjectContext)
        let categories = post.mutableSetValueForKey("categories")
        categories.removeAllObjects()
        for remoteCategory in remoteCategories
        {
            if let category = categoryService.findWithBlogObjectID(blogObjectID, andCategoryID: remoteCategory.categoryID) {
                category.categoryID = remoteCategory.categoryID
                category.categoryName = remoteCategory.name
                category.parentID = remoteCategory.parentID
                categories.addObject(category)
            }
        }
    }

    func updateComments(for post: AbstractPost) {
        let commentService = CommentService(managedObjectContext: self.managedObjectContext)
        let currentComments = post.mutableSetValueForKey("comments")
        let allComments = commentService.findCommentsWithPostID(post.postID, inBlog: post.blog)
        currentComments.addObjectsFromArray(Array(allComments))
    }

    func dictionary(with key: NSString, in metadata: [[String : AnyObject]]) -> [String : AnyObject]? {
        let matchingEntries = metadata.filter {
            $0["key"] as! String == key
        }
        // In theory, there shouldn't be duplicated fields, but I've seen some bugs where there's more than one geo_* value
        // In any case, they should be sorted by id, so `lastObject` should have the newer value - @koke
        return matchingEntries.last
    }

    func remote(for blog: Blog) -> PostServiceRemote? {
        var remote: PostServiceRemote?
        if blog.supports(.WPComRESTAPI) {
            if let wpComRestApi = blog.wordPressComRestApi() {
                remote = PostServiceRemoteREST(wordPressComRestApi: wpComRestApi, siteID: blog.dotComID!)
            }
        } else if let xmlrpcApi = blog.xmlrpcApi {
            remote = PostServiceRemoteXMLRPC(api: xmlrpcApi, username: blog.username!, password: blog.password!)
        }
        return remote
    }
}

// MARK: - for Objective-C

extension PostService {
    @objc(syncPostsOfType:withOptions:forBlog:success:failure:)
    func sync(typeKey: PostServiceType, options: PostServiceSyncOptions?, blog: Blog, success: SuccessPosts?, failure: FailureBasic?) {
        sync(PostType(rawValue:typeKey as String)!, blog: blog, options: options, success: success, failure: failure)
    }
}
