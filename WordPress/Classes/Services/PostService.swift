import Foundation

class PostService : LocalCoreDataService {
    static let PostServiceErrorDomain = "PostServiceErrorDomain"
    static let PostServiceDefaultNumberToSync = 40

    enum PostType: String {
        case Any = "any"
        case Post = "post"
        case Page = "page"
    }

    typealias SyncSuccess = ([AbstractPost]) -> Void
    typealias SyncFailure = (NSError?) -> Void

    convenience override init() {
        self.init(managedObjectContext: ContextManager.sharedInstance().mainContext)
    }

    func createPost(for blog: Blog) -> Post {
        assert(self.managedObjectContext == blog.managedObjectContext, "Blog's context should be the the same as the service's")

        let post = NSEntityDescription.insertNewObjectForEntityForName(Post.entityName(), inManagedObjectContext: self.managedObjectContext) as! Post
        post.blog = blog
        post.remoteStatus = AbstractPostRemoteStatusSync
        let postCategoryService = PostCategoryService(managedObjectContext:self.managedObjectContext)
        if let category = postCategoryService.findWithBlogObjectID(blog.objectID, andCategoryID: (blog.settings?.defaultCategoryID)!) {
            post.addCategoriesObject(category)
        }
        post.postFormat = blog.settings?.defaultPostFormat
        post.postType = Post.typeDefaultIdentifier
        return post
    }

    func createDraftPost(for blog: Blog) -> Post {
        let post = self.createPost(for: blog)
        post.remoteStatus = AbstractPostRemoteStatusLocal
        return post
    }

    func createPage(for blog: Blog) -> Page {
        assert(self.managedObjectContext == blog.managedObjectContext, "Blog's context should be the the same as the service's")
        let page = NSEntityDescription.insertNewObjectForEntityForName(Page.entityName(), inManagedObjectContext: self.managedObjectContext) as! Page
        page.blog = blog
        page.remoteStatus = AbstractPostRemoteStatusSync
        return page
    }

    func createDraftPage(for blog: Blog) -> Page {
        let page = self.createPage(for: blog)
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

    func syncPosts(ofType type: PostType, for blog: Blog, success: SyncSuccess, failure: SyncFailure) {
        self.syncPosts(ofType: type, for: blog, options: nil, success: success, failure: failure)
    }

    func syncPosts(ofType type: PostType, for blog: Blog, options: PostServiceSyncOptions?, success: SyncSuccess, failure: SyncFailure) {
        if let remote = self.remote(for:blog) {
            let blogID = blog.objectID
            let remoteOptions = self.remoteSyncParameters(for:remote, with:options)
            remote.getPostsOfType(type.rawValue, options: remoteOptions, success: { (remotePosts) in
                    self.managedObjectContext.performBlock({
                        do {
                            let blogInContext = try self.managedObjectContext.existingObjectWithID(blogID)
                        } catch {
                            DDLogSwift.logError("Could not retrieve blog in context %@", error ? String(format: "with error: %@", error) : "")
                        }
                    })
                }, failure: { (error) in
                    // TODO:
            })
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
