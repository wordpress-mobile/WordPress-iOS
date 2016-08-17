import Foundation

class PostService : LocalCoreDataService {
    static let PostServiceErrorDomain = "PostServiceErrorDomain"
    static let PostServiceDefaultNumberToSync = 40

    enum PostType: String {
        case any = "any"
        case post = "post"
        case page = "page"

        func type() -> AbstractPost.Type {
            switch self {
            case .post: return Post.self
            case .page: return Page.self
            default: return AbstractPost.self
            }
        }
    }

    typealias SyncSuccess = ([AbstractPost]) -> Void
    typealias SyncFailure = (NSError?) -> Void

    convenience override init() {
        self.init(managedObjectContext: ContextManager.sharedInstance().mainContext)
    }

    func create(postType: PostType?, blog: Blog) -> AbstractPost? {
        return create(postType?.type() ?? Post.self, blog: blog)
    }

    func create<T: AbstractPost>(postType: T.Type, blog: Blog) -> T? {
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

    func createDraftPost(for blog: Blog) -> Post? {
        guard let post = self.create(Post.self, blog: blog) else { return nil }
        post.remoteStatus = AbstractPostRemoteStatusLocal
        return post
    }

    func createDraftPage(for blog: Blog) -> Page? {
        guard let page = self.create(Page.self, blog: blog) else { return nil }
        page.remoteStatus = AbstractPostRemoteStatusLocal
        return page
    }

    func get(byId postID: Int, blog: Blog, success: (AbstractPost?) -> Void, failure: ((NSError?) -> Void)?) {
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
                                        
                                        let post = self.find(byID: postID, blog: blogInContext) ?? self.create(.post, blog: blogInContext)
                                        
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

    func syncPosts(ofType type: PostType, blog: Blog, success: SyncSuccess, failure: SyncFailure) {
        self.syncPosts(ofType: type, blog: blog, options: nil, success: success, failure: failure)
    }

    func syncPosts(ofType type: PostType, blog: Blog, options: PostServiceSyncOptions?, success: SyncSuccess, failure: SyncFailure) {
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
                                    author: options?.authorID as Int?,
                                    blog: blogInContext,
                                    purge: options?.purgesLocalSync,
                                    completion: { (posts) in
                                        success(posts)
                                })
                            }
                        } catch let error as NSError? {
                            DDLogSwift.logError(String("Could not retrieve blog in context with error: %@", error))
                        }
                    })
                }, failure: { (error) in
                    self.managedObjectContext.performBlock({
                        failure(error)
                    })
            })
        }
    }
    
    func upload(post: AbstractPost, success: (AbstractPost?) -> Void, failure: (NSError?) -> Void) {
        let remote = self.remote(for: post.blog)
        let remotePost = self.remotePost(withPost: post)
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

    func merge(posts remotePosts: [RemotePost], type: PostType, statuses: [String]?, author authorID: Int?, blog: Blog, purge: Bool?, completion: ([AbstractPost]) -> Void) {
        let posts: [AbstractPost] = remotePosts.flatMap { remotePost in
            if let post = self.find(byID: remotePost.postID as Int, blog: blog) ?? self.create(PostType(rawValue:remotePost.type), blog: blog) {
                self.update(post, with: remotePost)
                return post
            }
            return nil
        }

        if let purge = purge where purge {
            var predicate = NSPredicate(format: "(remoteStatusNumber = %@) AND (postID != NULL) AND (original = NULL) AND (revision = NULL) AND (blog = %@)", AbstractPostRemoteStatusSync.rawValue, blog)
            if let statuses = statuses where statuses.count > 0 {
                let statusPredicate = NSPredicate(format: "status IN %@", statuses)
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, statusPredicate])
            }
            if let authorID = authorID {
                let authorPredicate = NSPredicate(format: "authorID IN %@", authorID)
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
                        DDLogSwift.logInfo(String("Deleting Post: %@", post))
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
        request.predicate = NSPredicate(format: "blog = %@ AND original = NULL AND postID = %@", blog, postID)
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

    func remotePost(withPost post: AbstractPost) -> RemotePost {
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
