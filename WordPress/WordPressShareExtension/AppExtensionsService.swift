import CoreData
import WordPressKit

/// Provides site fetching and post/media uploading functionality to app extensions.
///
class AppExtensionsService {

    typealias CompletionBlock = () -> Void
    typealias FailureBlock = () -> Void

    // MARK: - Private Properties

    /// Unique identifier a group of upload operations
    ///
    fileprivate lazy var groupIdentifier: String = {
        let groupIdentifier = UUID().uuidString
        return groupIdentifier
    }()

    /// Unique identifier for background sessions
    ///
    fileprivate lazy var backgroundSessionIdentifier: String = {
        let identifier = WPAppGroupName + "." + UUID().uuidString
        return identifier
    }()

    /// WordPress.com OAuth Token
    ///
    fileprivate lazy var oauth2Token: String? = {
        ShareExtensionService.retrieveShareExtensionToken()
    }()

    /// Simple Rest API (no backgrounding)
    ///
    fileprivate lazy var simpleRestAPI: WordPressComRestApi = {
        WordPressComRestApi(oAuthToken: oauth2Token,
                            userAgent: nil,
                            backgroundUploads: false,
                            backgroundSessionIdentifier: backgroundSessionIdentifier,
                            sharedContainerIdentifier: WPAppGroupName)
    }()

    /// Tracks Instance
    ///
    fileprivate lazy var tracks: Tracks = {
        Tracks(appGroupName: WPAppGroupName)
    }()

    /// WordPress.com Username
    ///
    internal lazy var wpcomUsername: String? = {
        ShareExtensionService.retrieveShareExtensionUsername()
    }()

    /// Core Data stack for application extensions
    ///
    fileprivate lazy var coreDataStack = SharedCoreDataStack()
    fileprivate var managedContext: NSManagedObjectContext!

    // MARK: - Initializers

    @objc required init() {
        // Tracker
        tracks.wpcomUsername = wpcomUsername

        // Core Data
        managedContext = coreDataStack.managedContext
    }

    deinit {
        coreDataStack.saveContext()
    }
}

// MARK: - Sites

extension AppExtensionsService {
    /// Fetches only visible blogs for the current account.
    ///
    /// - Parameters:
    ///   - onSuccess: Completion handler executed after a successful fetch.
    ///   - onFailure: The failure handler.
    ///
    func fetchSites(onSuccess: @escaping ([RemoteBlog]?) -> (), onFailure: @escaping FailureBlock) {
        let remote = AccountServiceRemoteREST(wordPressComRestApi: simpleRestAPI)
        remote?.getVisibleBlogs(success: { blogs in
            onSuccess(blogs as? [RemoteBlog])
            }, failure: { error in
                DDLogError("Error retrieving blogs: \(String(describing: error))")
                onFailure()
        })
    }
}

// MARK: - Uploading Posts

extension AppExtensionsService {
    /// Saves a new post to the share container db and then uploads it synchronously.
    ///
    /// - Parameters:
    ///   - title: Post title
    ///   - body: Post content body
    ///   - status: Post status
    ///   - siteID: Site ID the post will be uploaded to
    ///   - onComplete: Completion handler executed after a post is uploaded to the server
    ///   - onFailure: The (optional) failure handler.
    ///
    func saveAndUploadPost(title: String, body: String, status: String, siteID: Int, onComplete: CompletionBlock?, onFailure: FailureBlock?) {
        guard let remotePost = RemotePost(siteID: NSNumber(value: siteID), status: status, title: title, content: body) else {
            DDLogError("Unable to create the post object required for uploading.")
            onFailure?()
            return
        }

        let uploadPostOpID = coreDataStack.savePostOperation(remotePost, groupIdentifier: groupIdentifier, with: .pending)
        uploadPost(forUploadOpWithObjectID: uploadPostOpID, onComplete: {
            onComplete?()
        }, onFailure: {
            // Error is already logged in coredata so no need to do it here.
            onFailure?()
        })
    }

    /// Uploads an already-saved post synchronously.
    ///
    /// - Parameters:
    ///   - uploadOpObjectID: Managed object ID for the post
    ///   - onComplete: Completion handler executed after a post is uploaded to the server.
    ///   - onFailure: The (optional) failure handler.
    ///
    func uploadPost(forUploadOpWithObjectID uploadOpObjectID: NSManagedObjectID, onComplete: CompletionBlock?, onFailure: FailureBlock?) {
        guard let postUploadOp = coreDataStack.fetchPostUploadOp(withObjectID: uploadOpObjectID) else {
            DDLogError("Error uploading post in share extension — could not fetch saved post.")
            onFailure?()
            return
        }

        let remotePost = postUploadOp.remotePost
        coreDataStack.updateStatus(.inProgress, forUploadOpWithObjectID: uploadOpObjectID)

        // 15-Nov-2017: Creating a post without media on the PostServiceRemoteREST does not use background uploads
        let remote = PostServiceRemoteREST(wordPressComRestApi: simpleRestAPI, siteID: remotePost.siteID)
        remote.createPost(remotePost, success: { post in
            if let post = post {
                DDLogInfo("Post \(post.postID.stringValue) sucessfully uploaded to site \(post.siteID.stringValue)")
                if let postID = post.postID {
                    self.coreDataStack.updatePostOperation(with: .complete, remotePostID: postID.int64Value, forPostUploadOpWithObjectID: uploadOpObjectID)
                } else {
                    self.coreDataStack.updateStatus(.complete, forUploadOpWithObjectID: uploadOpObjectID)
                }
                onComplete?()
            }
        }, failure: { error in
            var errorString = "Error creating post in share extension"
            if let error = error as NSError? {
                errorString += ": \(error.localizedDescription)"
            }
            DDLogError(errorString)
            self.coreDataStack.updateStatus(.error, forUploadOpWithObjectID: uploadOpObjectID)
            onFailure?()
        })
    }

    /// Saves a new post + media items to the shared container db and then uploads it in the background. 
    ///
    /// - Parameters:
    ///   - title: Post title
    ///   - body: Post content body
    ///   - status: Post status
    ///   - siteID: Site ID the post will be uploaded to
    ///   - localMediaFileURLs: An array of local URLs containing the media files to upload
    ///   - requestEnqueued: Completion handler executed when the media has been processed and background upload is scheduled.
    ///   - onFailure: The failure handler.
    ///
    func uploadPostWithMedia(title: String,
                             body: String,
                             status: String,
                             siteID: Int,
                             localMediaFileURLs: [URL],
                             requestEnqueued: @escaping CompletionBlock,
                             onFailure: @escaping FailureBlock) {
        guard !localMediaFileURLs.isEmpty else {
            DDLogError("No media is attached to this upload request")
            onFailure()
            return
        }
        guard let remotePost = RemotePost(siteID: NSNumber(value: siteID), status: status, title: title, content: body) else {
            DDLogError("Unable to create the post object required for uploading.")
            onFailure()
            return
        }

        // Create the post & media upload ops
        let uploadPostOpID = coreDataStack.savePostOperation(remotePost, groupIdentifier: groupIdentifier, with: .pending)
        let (uploadMediaOpIDs, allRemoteMedia) = createAndSaveRemoteMediaWithLocalURLs(localMediaFileURLs, siteID: NSNumber(value: siteID))

        // Setup an API that uses background uploads with the shared container
        let api = WordPressComRestApi(oAuthToken: oauth2Token,
                                      userAgent: nil,
                                      backgroundUploads: true,
                                      backgroundSessionIdentifier: backgroundSessionIdentifier,
                                      sharedContainerIdentifier: WPAppGroupName)

        // NOTE: The success and error closures **may** get called here - it’s non-deterministic as to whether WPiOS
        // or the extension gets the "did complete" callback. So unfortunatly, we need to have the logic to complete
        // post share here as well as WPiOS.
        let remote = MediaServiceRemoteREST(wordPressComRestApi: api, siteID: NSNumber(value: siteID))
        remote.uploadMedia(allRemoteMedia, requestEnqueued: { taskID in
            uploadMediaOpIDs.forEach({ uploadMediaOpID in
                self.coreDataStack.updateStatus(.inProgress, forUploadOpWithObjectID: uploadMediaOpID)
                if let taskID = taskID {
                    self.coreDataStack.updateTaskID(taskID, forUploadOpWithObjectID: uploadMediaOpID)
                }
            })
            requestEnqueued()
        }, success: { remoteMedia in
            guard let returnedMedia = remoteMedia as? [RemoteMedia],
                returnedMedia.count > 0,
                let mediaUploadOps = self.coreDataStack.fetchMediaUploadOps(for: self.groupIdentifier) else {
                    DDLogError("Error creating post in share extension. RemoteMedia info not returned from server.")
                    return
            }

            mediaUploadOps.forEach({ mediaUploadOp in
                returnedMedia.forEach({ remoteMedia in
                    if let remoteMediaID = remoteMedia.mediaID?.int64Value,
                        let remoteMediaURLString = remoteMedia.url?.absoluteString,
                        let localFileName = mediaUploadOp.fileName,
                        let remoteFileName = remoteMedia.file {

                        if localFileName.lowercased().trim() == remoteFileName.lowercased().trim() {
                            mediaUploadOp.remoteURL = remoteMediaURLString
                            mediaUploadOp.remoteMediaID = remoteMediaID
                            mediaUploadOp.currentStatus = .complete

                            if let width = remoteMedia.width?.int32Value,
                                let height = remoteMedia.width?.int32Value {
                                mediaUploadOp.width = width
                                mediaUploadOp.height = height
                            }

                            ShareMediaFileManager.shared.removeFromUploadDirectory(fileName: localFileName)
                        }
                    }
                })
            })
            self.coreDataStack.saveContext()

            // Now upload the post
            self.combinePostWithMediaAndUpload(forPostUploadOpWithObjectID: uploadPostOpID)
        }) { error in
            guard let error = error as NSError? else {
                return
            }
            DDLogError("Error creating post in share extension: \(error.localizedDescription)")
            uploadMediaOpIDs.forEach({ uploadMediaOpID in
                self.coreDataStack.updateStatus(.error, forUploadOpWithObjectID: uploadMediaOpID)
            })
            onFailure()
        }
    }
}

// MARK: - Private Helpers

fileprivate extension AppExtensionsService {
    func createAndSaveRemoteMediaWithLocalURLs(_ localMediaFileURLs: [URL], siteID: NSNumber) -> ([NSManagedObjectID], [RemoteMedia]) {
        // Process all of the media items and create their upload ops
        var uploadMediaOpIDs = [NSManagedObjectID]()
        var allRemoteMedia = [RemoteMedia]()
        localMediaFileURLs.forEach { tempFilePath in
            let remoteMedia = RemoteMedia()
            remoteMedia.file = tempFilePath.lastPathComponent
            remoteMedia.mimeType = Constants.mimeType
            remoteMedia.localURL = tempFilePath
            allRemoteMedia.append(remoteMedia)

            let uploadMediaOpID = coreDataStack.saveMediaOperation(remoteMedia,
                                                                   sessionID: backgroundSessionIdentifier,
                                                                   groupIdentifier: groupIdentifier,
                                                                   siteID: siteID,
                                                                   with: .pending)
            uploadMediaOpIDs.append(uploadMediaOpID)
        }

        return (uploadMediaOpIDs, allRemoteMedia)
    }

    func combinePostWithMediaAndUpload(forPostUploadOpWithObjectID uploadPostOpID: NSManagedObjectID) {
        guard let postUploadOp = coreDataStack.fetchPostUploadOp(withObjectID: uploadPostOpID),
            let groupID = postUploadOp.groupID,
            let mediaUploadOps = coreDataStack.fetchMediaUploadOps(for: groupID) else {
                return
        }

        mediaUploadOps.forEach { mediaUploadOp in
            guard let fileName = mediaUploadOp.fileName,
                let remoteURL = mediaUploadOp.remoteURL else {
                    return
            }

            let imgPostUploadProcessor = ImgUploadProcessor(mediaUploadID: fileName,
                                                            remoteURLString: remoteURL,
                                                            width: Int(mediaUploadOp.width),
                                                            height: Int(mediaUploadOp.height))
            let content = postUploadOp.postContent ?? ""
            postUploadOp.postContent = imgPostUploadProcessor.process(content)
        }
        coreDataStack.saveContext()
        uploadPost(forUploadOpWithObjectID: uploadPostOpID, onComplete: nil, onFailure: nil)
    }
}

// MARK: - Constants

extension AppExtensionsService {
    struct Constants {
        static let mimeType = "image/jpeg"
    }
}
