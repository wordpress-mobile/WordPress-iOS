import CoreData
import UIKit
import WordPressKit

/// A base class for the various Share Extension view controllers.
/// It is assumed that Share Extension controllers will always be presented modally.
///
class ShareExtensionAbstractViewController: UIViewController, ShareSegueHandler {

    enum SegueIdentifier: String {
        case showModularSitePicker
    }

    typealias CompletionBlock = () -> Void

    /// This completion handler closure is executed when this VC is dismissed
    ///
    @objc var cancelCompletionBlock: CompletionBlock?

    /// Stateful data related to this share session.
    ///
    var shareData = ShareData()

    // MARK: - Internal Properties

    /// WordPress.com Username
    ///
    internal lazy var wpcomUsername: String? = {
        ShareExtensionService.retrieveShareExtensionUsername()
    }()

    /// WordPress.com OAuth Token
    ///
    internal lazy var oauth2Token: String? = {
        ShareExtensionService.retrieveShareExtensionToken()
    }()

    /// Selected Site's ID
    ///
    internal lazy var selectedSiteID: Int? = {
        ShareExtensionService.retrieveShareExtensionDefaultSite()?.siteID
    }()

    /// Selected Site's Name
    ///
    internal lazy var selectedSiteName: String? = {
        ShareExtensionService.retrieveShareExtensionDefaultSite()?.siteName
    }()

    /// Maximum Image Size
    ///
    internal lazy var maximumImageSize: CGSize = {
        let dimension = ShareExtensionService.retrieveShareExtensionMaximumMediaDimension() ?? Constants.defaultMaxDimension
        return CGSize(width: dimension, height: dimension)
    }()

    /// Tracks Instance
    ///
    internal lazy var tracks: Tracks = {
        Tracks(appGroupName: WPAppGroupName)
    }()

    /// Unique identifier a group of upload operations
    ///
    internal lazy var groupIdentifier: String = {
        let groupIdentifier = UUID().uuidString
        return groupIdentifier
    }()

    /// Unique identifier for background sessions
    ///
    internal lazy var backgroundSessionIdentifier: String = {
        let identifier = WPAppGroupName + "." + UUID().uuidString
        return identifier
    }()

    /// Core Data stack for application extensions
    ///
    internal lazy var coreDataStack = SharedCoreDataStack()
    internal var managedContext: NSManagedObjectContext!

    // MARK: - Lifecycle Methods

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Tracker
        tracks.wpcomUsername = wpcomUsername

        // Core Data
        managedContext = coreDataStack.managedContext
    }

    // MARK: Setup and Configuration

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait
    }
}

// MARK: - Misc Helpers

extension ShareExtensionAbstractViewController {

    func saveImageToSharedContainer(_ image: UIImage) -> URL? {
        guard let encodedMedia = image.resizeWithMaximumSize(maximumImageSize).JPEGEncoded(),
            let mediaDirectory = ShareMediaFileManager.shared.mediaUploadDirectoryURL else {
                return nil
        }

        let uniqueString = "image_\(NSDate.timeIntervalSinceReferenceDate)"
        let fileName = uniqueString.components(separatedBy: ["."]).joined() + ".jpg"
        let fullPath = mediaDirectory.appendingPathComponent(fileName)
        do {
            try encodedMedia.write(to: fullPath, options: [.atomic])
        } catch {
            DDLogError("Error saving \(fullPath) to shared container: \(String(describing: error))")
            return nil
        }
        return fullPath
    }

    func cleanUpSharedContainer() {
        // First, remove the temp media files if needed
        for tempMediaFileURL in shareData.sharedImageDict.values {
            if !tempMediaFileURL.pathExtension.isEmpty {
                ShareMediaFileManager.shared.removeFromUploadDirectory(fileName: tempMediaFileURL.lastPathComponent)
            }
        }
    }
}

// MARK: - Backend Interaction

extension ShareExtensionAbstractViewController {

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

        self.uploadPost(forUploadOpWithObjectID: uploadPostOpID, requestEnqueued: {})
    }

    func uploadPost(forUploadOpWithObjectID uploadOpObjectID: NSManagedObjectID, requestEnqueued: @escaping () -> ()) {
        guard let postUploadOp = coreDataStack.fetchPostUploadOp(withObjectID: uploadOpObjectID) else {
            DDLogError("Error uploading post in share extension — could not fetch saved post.")
            requestEnqueued()
            return
        }

        let remotePost = postUploadOp.remotePost

        // 15-Nov-2017: Creating a post without media on the PostServiceRemoteREST does not use background uploads so set it false
        let api = WordPressComRestApi(oAuthToken: oauth2Token,
                                      userAgent: nil,
                                      backgroundUploads: false,
                                      backgroundSessionIdentifier: backgroundSessionIdentifier,
                                      sharedContainerIdentifier: WPAppGroupName)
        let remote = PostServiceRemoteREST(wordPressComRestApi: api, siteID: NSNumber(value: postUploadOp.siteID))
        remote.createPost(remotePost, success: { post in
            if let post = post {
                DDLogInfo("Post \(post.postID.stringValue) sucessfully uploaded to site \(post.siteID.stringValue)")
                if let postID = post.postID {
                    self.coreDataStack.updatePostOperation(with: .complete, remotePostID: postID.int64Value, forPostUploadOpWithObjectID: uploadOpObjectID)
                } else {
                    self.coreDataStack.updateStatus(.complete, forUploadOpWithObjectID: uploadOpObjectID)
                }
            }
            requestEnqueued()
        }, failure: { error in
            var errorString = "Error creating post in share extension"
            if let error = error as NSError? {
                errorString += ": \(error.localizedDescription)"
            }
            DDLogError(errorString)
            self.coreDataStack.updateStatus(.error, forUploadOpWithObjectID: uploadOpObjectID)
            requestEnqueued()
        })
    }

    func uploadPostWithMedia(subject: String, body: String, status: String, siteID: Int, requestEnqueued: @escaping () -> ()) {
        let tempMediaFileURLs = shareData.sharedImageDict.values
        guard tempMediaFileURLs.count > 0 else {
            DDLogError("No media is attached to this upload request.")
            requestEnqueued()
            return
        }

        // First create the post upload op
        let remotePost: RemotePost = {
            let post = RemotePost()
            post.siteID = NSNumber(value: siteID)
            post.status = status
            post.title = subject
            post.content = body
            return post
        }()
        let uploadPostOpID = coreDataStack.savePostOperation(remotePost, groupIdentifier: groupIdentifier, with: .pending)

        // Now process all of the media items and create their upload ops
        var uploadMediaOpIDs = [NSManagedObjectID]()
        var allRemoteMedia = [RemoteMedia]()
        tempMediaFileURLs.forEach { tempFilePath in
            let remoteMedia = RemoteMedia()
            remoteMedia.file = tempFilePath.lastPathComponent
            remoteMedia.mimeType = Constants.mimeType
            remoteMedia.localURL = tempFilePath
            allRemoteMedia.append(remoteMedia)

            let uploadMediaOpID = coreDataStack.saveMediaOperation(remoteMedia,
                                                                   sessionID: backgroundSessionIdentifier,
                                                                   groupIdentifier: groupIdentifier,
                                                                   siteID: NSNumber(value: siteID),
                                                                   with: .pending)
            uploadMediaOpIDs.append(uploadMediaOpID)
        }

        // Upload the media items
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
            self.tracks.trackExtensionError(error)
        }
    }
}

// MARK: - Constants

extension ShareExtensionAbstractViewController {

    struct Constants {
        static let placeholderMediaLink         = URL(string: "placeholder://")!
        static let defaultMaxDimension          = 3000
        static let mimeType                     = "image/jpeg"

        static let postStatuses = [
            "draft": NSLocalizedString("Draft", comment: "Draft post status"),
            "publish": NSLocalizedString("Publish", comment: "Publish post status")
        ]
    }
}

