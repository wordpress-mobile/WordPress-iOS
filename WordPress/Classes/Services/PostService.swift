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

    func create(postType: PostType, blog: Blog) -> AbstractPost? {
        return create(postType.type(), blog: blog)
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

    func get(byId postID: Int, blog: Blog, success: (AbstractPost) -> Void, failure: ((NSError?) -> Void)?) {
        if let remote = self.remote(for:blog) {
            let blogID = blog.objectID
            remote.getPostWithID(postID,
                                 success: { (remotePost: RemotePost?) -> Void in
                                    self.managedObjectContext.performBlock({
                                        guard let remotePost = remotePost,
                                        let blogX = try? self.managedObjectContext.existingObjectWithID(blogID) as! Blog
                                        else {
                                            if let failure = failure {
                                                let userInfo = [NSLocalizedDescriptionKey: "Retrieved remote post is nil"]
                                                failure(NSError(domain: ReaderPostServiceErrorDomain, code: 0, userInfo: userInfo))
                                            }
                                            return
                                        }
                                        var post = self.find(byID: postID, blog: blogX)
                                        if post == nil {
                                            post = self.createPost(for: blogX)
                                        }
                                        self.update(post!, with:remotePost)
                                        ContextManager.sharedInstance().saveContext(self.managedObjectContext)

                                        success(post!)
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
                            let blogInContext = try self.managedObjectContext.existingObjectWithID(blogID)
//                            self.merge(

                        } catch let error as NSError? {
                            DDLogSwift.logError(String("Could not retrieve blog in context with error: %@", error))
                        }
                    })
                }, failure: { (error) in
                    // TODO:
            })
        }
    }

    func merge(posts remotePosts: [RemotePost], type: PostType, statuses: [String], author authorID: Int, blog: Blog, purge: Bool, completion: ([AbstractPost]) -> Void) {
        let posts = [AbstractPost]
        for remotePost in remotePosts {
            var post = self.find(byID: remotePost.postID as Int, blog: blog)
            
        }
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
        // TODO: implement
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
