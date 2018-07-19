import Aztec
import Foundation
import CoreData
import WordPressFlux

/// Manages URLSessions initiated by the share extension
///
@objc class ShareExtensionSessionManager: NSObject {

    typealias CompletionBlock = () -> Void

    // MARK: - Public Properties

    typealias ShareExtensionBackgroundCompletionBlock = () -> Void
    @objc var backgroundSessionCompletionBlock: ShareExtensionBackgroundCompletionBlock?

    // MARK: - Private Properties

    fileprivate let backgroundSessionIdentifier: String
    fileprivate let appGroup: String
    fileprivate lazy var backgroundSession: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: self.backgroundSessionIdentifier)
        configuration.sharedContainerIdentifier = self.appGroup
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()

    /// Core Data stack for application extensions
    ///
    fileprivate lazy var coreDataStack = SharedCoreDataStack()

    // MARK: - Initializers

    @objc required init(appGroup: String, backgroundSessionIdentifier: String) {
        self.appGroup = appGroup
        self.backgroundSessionIdentifier = backgroundSessionIdentifier
    }

    deinit {
        shutdown()
    }

    // MARK: - Public Funcntions

    /// Invalidates the background URLSession allowing any outstanding tasks to complete.
    ///
    @objc func shutdown() {
        backgroundSession.finishTasksAndInvalidate()
    }

    /// Cancels all outstanding tasks and invalidates the background URLSession.
    ///
    @objc func forceShutdown() {
        backgroundSession.invalidateAndCancel()
    }

    /// Starts up the background URLSession with the sharedContainerIdentifier (appGroup) and backgroundSessionIdentifier
    /// passed into init().
    ///
    @objc func startBackgroundSession() {
        DDLogInfo("Initializing background session: \(backgroundSession)")
    }

    /// Displays a notification to the user about the successful/error-ridden post if necessary.
    ///
    /// - Parameter postUploadOp: The post UploadOperation in question
    ///
    static func fireUserNotificationIfNeeded(_ postUploadOpID: String) {
        let coreDataStack = SharedCoreDataStack()
        coreDataStack.managedContext.refreshAllObjects()
        guard let postUploadOp = coreDataStack.fetchPostUploadOp(withObjectID: postUploadOpID) else {
            return
        }

        let uploadStatus = postUploadOp.currentStatus
        var uploadedMediaCount = 0

        if uploadStatus == .error {
            // The post upload failed
            let model = ShareNoticeViewModel(post: nil, uploadStatus: uploadStatus, uploadedMediaCount: uploadedMediaCount)
            if let notice = model?.notice {
                ActionDispatcher.dispatch(NoticeAction.post(notice))
            }
        } else {
            // The post upload was successful
            if let groupID = postUploadOp.groupID, let mediaUploadOps = coreDataStack.fetchMediaUploadOps(for: groupID) {
                uploadedMediaCount = mediaUploadOps.count
            }

            let context = ContextManager.sharedInstance().mainContext
            let blogService = BlogService(managedObjectContext: context)
            guard let blog = blogService.blog(byBlogId: NSNumber(value: postUploadOp.siteID)) else {
                return
            }

            // Sync the remote post to WPiOS so that we can open it for editing if needed.
            let postService = PostService(managedObjectContext: context)
            postService.getPostWithID(NSNumber(value: postUploadOp.remotePostID), for: blog, success: { post in
                guard let post = post as? Post else {
                    return
                }

                let model = ShareNoticeViewModel(post: post, uploadStatus: uploadStatus, uploadedMediaCount: uploadedMediaCount)
                if let notice = model?.notice {
                    ActionDispatcher.dispatch(NoticeAction.post(notice))
                }
            }) { error in
                DDLogError("Unable to create user notification for share extension session with.")
            }
        }
    }

    // MARK: - Private Functions

    /// Clean up the session manager and end things gracefully (run the stored completion block, etc). Run
    /// this after all the session tasks are completed.
    ///
    fileprivate func cleanupSessionAndTerminate() {
        // Run the stored completetion block for the session
        if let completionHandler = backgroundSessionCompletionBlock {
            backgroundSessionCompletionBlock = nil
            DispatchQueue.main.async {
                completionHandler()
            }
        }
        DDLogInfo("Completed processing post and media upload for session \(backgroundSessionIdentifier).")
    }

    /// Logs the error and updates the upload op's status with `Error`
    ///
    /// - Parameters:
    ///   - errorString: Error string to log
    ///   - uploadOpObjectIDs: Array of object IDs
    ///
    fileprivate func logError(_ errorString: String, uploadOpObjectIDs: [NSManagedObjectID]) {
        guard uploadOpObjectIDs.count > 0 else {
            return
        }
        DDLogError(errorString)
        for uploadOpObjectID in uploadOpObjectIDs {
            coreDataStack.updateStatus(.error, forUploadOpWithObjectID: uploadOpObjectID)
        }
    }

    fileprivate func logError(_ errorString: String, uploadOpObjectIDs: NSManagedObjectID...) {
        logError(errorString, uploadOpObjectIDs: uploadOpObjectIDs)
    }

    /// Appends all of the remote media URLs to the post's content property.
    /// For the provided group ID:
    ///   1. Find the (not completed) post upload op (there should be one)
    ///   2. Find all of the completed media upload ops
    ///   3. Update the media in tags within the postContent property of the post upload op
    ///   4. Save the post upload op and return it
    ///
    /// - Parameter groupID: Group ID representing all of the media upload ops and single post upload op
    /// - Returns: The updated post PostUploadOperation or nil
    ///
    fileprivate func combinePostAndMediaContent(for groupID: String) -> PostUploadOperation? {
        guard let postUploadOp = postUploadOperation(for: groupID),
            let mediaUploadOps = mediaUploadOperations(for: groupID) else {
                return nil
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

        return postUploadOp
    }

    /// Uploads a post to the server
    ///
    /// - Parameter postUploadOp: The UploadOperation that represents a post
    ///
    fileprivate func uploadPost(with postUploadOp: PostUploadOperation) {
        let postUploadOpID = postUploadOp.objectID
        guard let oauth2Token = token() else {
            logError("Error creating post: OAuth token is not defined.", uploadOpObjectIDs: postUploadOpID)
            return
        }
        guard postUploadOp.siteID > 0 else {
            logError("Error creating post: site ID was missing.", uploadOpObjectIDs: postUploadOpID)
            return
        }

        let remote = PostServiceRemoteREST(wordPressComRestApi: api(token: oauth2Token), siteID: NSNumber(value: postUploadOp.siteID))
        postUploadOp.currentStatus = .inProgress
        coreDataStack.saveContext()

        remote.createPost(postUploadOp.remotePost, success: { post in
            guard let post = post else {
                return
            }

            if let postID = post.postID {
                DDLogInfo("Post \(post.postID.stringValue) successfully uploaded to site \(post.siteID.stringValue)")
                postUploadOp.remotePostID = postID.int64Value
            }
            postUploadOp.currentStatus = .complete

            self.coreDataStack.saveContext()

            self.updateMedia(postID: post.postID.int64Value, siteID: postUploadOp.siteID, onComplete: {
                ShareExtensionSessionManager.fireUserNotificationIfNeeded(postUploadOpID.uriRepresentation().absoluteString)
                self.cleanupSessionAndTerminate()
            })
        }, failure: { error in
            var errorString = "Error creating post"
            if let error = error as NSError? {
                errorString += ": \(error.localizedDescription)"
            }
            self.logError(errorString, uploadOpObjectIDs: postUploadOpID)
            ShareExtensionSessionManager.fireUserNotificationIfNeeded(postUploadOpID.uriRepresentation().absoluteString)
            self.cleanupSessionAndTerminate()
        })
    }

    private func api(token: String) -> WordPressComRestApi {
        return WordPressComRestApi(oAuthToken: token,
                                   userAgent: nil,
                                   backgroundUploads: false,
                                   backgroundSessionIdentifier: backgroundSessionIdentifier,
                                   sharedContainerIdentifier: WPAppGroupName)
    }

    private func token() -> String? {
        return ShareExtensionService.retrieveShareExtensionToken()
    }

    private func updateMedia(postID: Int64?, siteID: Int64, onComplete: CompletionBlock?) {
        guard let postID = postID else {
            return
        }

        guard let service = mediaService(siteID: siteID) else {
            return
        }

        guard let groupID = coreDataStack.fetchGroupID(for: backgroundSessionIdentifier), !groupID.isEmpty else {
            DDLogError("Unable to find the Group ID for session with ID \(backgroundSessionIdentifier).")
            return
        }

        let media = mediaUploadOperations(for: groupID)?.compactMap({return $0.remoteMedia})
        let syncGroup = DispatchGroup()
        media?.forEach { mediaItem in
            syncGroup.enter()
            mediaItem.postID = NSNumber(value: postID)
            service.update(mediaItem, success: { updatedRemoteMedia in
                syncGroup.leave()
            }, failure: { error in
                var errorString = "Error creating post in share extension"
                if let error = error as NSError? {
                    errorString += ": \(error.localizedDescription)"
                }
                DDLogError(errorString)
                syncGroup.leave()
            })
        }

        syncGroup.notify(queue: .main) {
            onComplete?()
        }
    }

    fileprivate func mediaService(siteID: Int64) -> MediaServiceRemoteREST? {
        guard let oauth2Token = token() else {
            return nil
        }
        return MediaServiceRemoteREST(wordPressComRestApi: api(token: oauth2Token), siteID: NSNumber(value: siteID))
    }

    private func mediaUploadOperations(for groupID: String) -> [MediaUploadOperation]? {
        return coreDataStack.fetchMediaUploadOps(for: groupID)
    }

    private func postUploadOperation(for groupID: String) -> PostUploadOperation? {
        return coreDataStack.fetchPostUploadOp(for: groupID)
    }
}

// MARK: - ShareExtensionSessionManager Extension: URLSessionTaskDelegate

extension ShareExtensionSessionManager: URLSessionDelegate {

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        guard let groupID = coreDataStack.fetchGroupID(for: backgroundSessionIdentifier), !groupID.isEmpty else {
            DDLogError("Unable to find the Group ID for session with ID \(backgroundSessionIdentifier).")
            return
        }
        guard let postUploadOp = combinePostAndMediaContent(for: groupID) else {
            DDLogError("Unable to append media to the post for Group ID \(groupID).")
            return
        }

        // Now the media is all uploaded, let's append it to the post and upload
        uploadPost(with: postUploadOp)
    }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            DDLogError("Background session invalidated by the system. Session:\(session) Error:\(error).")

            // We are only going to send errors to Tracks that are NOT related to the "lite" tracks client
            // in the share extension. See https://github.com/wordpress-mobile/WordPress-iOS/issues/9789
            // for more details.
            if (error as NSError).description.contains("tracks/record") == false {
                WPAppAnalytics.track(.shareExtensionError, error: error)
            }
        } else {
            DDLogError("Background session explicitly invalidated by WPiOS. Session:\(session).")
        }
    }
}

// MARK: - ShareExtensionSessionManager Extension: URLSessionTaskDelegate

extension ShareExtensionSessionManager: URLSessionTaskDelegate {

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        DDLogDebug("didSendBodyData [session:\(session) task:\(task.debugDescription) bytesSent:\(bytesSent) totalBytesSent:\(totalBytesSent) totalBytesExpectedToSend:\(totalBytesExpectedToSend)]")
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let uploadOps = coreDataStack.fetchSessionUploadOps(for: task.taskIdentifier, with: backgroundSessionIdentifier) else {
            DDLogError("Background session tasks were not found in shared database. Session:\(session) Task:\(task.debugDescription).")
            return
        }

        if let error = error {
            logError("Background session task completed with error. Session:\(session) Task:\(task.debugDescription) Error:\(error).",
                uploadOpObjectIDs: uploadOps.map({ $0.objectID }))
            WPAppAnalytics.track(.shareExtensionError, error: error)
            return
        }

        uploadOps.forEach { uploadOp in
            if let mediaUploadOp = uploadOp as? MediaUploadOperation, let fileName = mediaUploadOp.fileName {
                ShareMediaFileManager.shared.removeFromUploadDirectory(fileName: fileName)
            }
            coreDataStack.updateStatus(.complete, forUploadOpWithObjectID: uploadOp.objectID)
        }
        DDLogInfo("Background session task completed. Session:\(session) Task:\(task.debugDescription).")
    }
}

// MARK: - ShareExtensionSessionManager Extension: URLSessionDataDelegate

extension ShareExtensionSessionManager: URLSessionDataDelegate {

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let object = try? JSONSerialization.jsonObject(with: data, options: []),
            let response = object as? [String: AnyObject],
            let media = response["media"] as? [[String: AnyObject]] else {
                DDLogError("Error parsing server response data. Task:\(dataTask.debugDescription)")
                return
        }

        media.forEach { mediaDict in
            // We need the filename here because multiple media files can be bundled into a single task
            guard let remoteFilenameString  = mediaDict["file"] as? String, !remoteFilenameString.isEmpty else {
                return
            }

            var mediaID: Int64?
            var width: Int32?
            var height: Int32?
            var urlString: String?
            if let remoteMediaID = mediaDict["ID"] as? NSNumber {
                mediaID = remoteMediaID.int64Value
            }
            if let remoteMediaUrlString  = mediaDict["URL"] as? String, !remoteMediaUrlString.isEmpty {
                urlString = remoteMediaUrlString
            }
            if let remoteMediaWidth = mediaDict["width"] as? NSNumber {
                width = remoteMediaWidth.int32Value
            }
            if let remoteMediaHeight = mediaDict["height"] as? NSNumber {
                height = remoteMediaHeight.int32Value
            }
            coreDataStack.updateMediaOperation(for: remoteFilenameString,
                                               with: backgroundSessionIdentifier,
                                               remoteMediaID: mediaID,
                                               remoteURL: urlString,
                                               width: width,
                                               height: height)
        }
    }
}
