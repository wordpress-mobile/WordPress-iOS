import UIKit
import Social
import WordPressKit

class ShareViewController: SLComposeServiceViewController {

    // MARK: - Private Properties

    /// WordPress.com Username
    ///
    fileprivate lazy var wpcomUsername: String? = {
        ShareExtensionService.retrieveShareExtensionUsername()
    }()

    /// WordPress.com OAuth Token
    ///
    fileprivate lazy var oauth2Token: String? = {
        ShareExtensionService.retrieveShareExtensionToken()
    }()

    /// Selected Site's ID
    ///
    fileprivate lazy var selectedSiteID: Int? = {
        ShareExtensionService.retrieveShareExtensionDefaultSite()?.siteID
    }()

    /// Selected Site's Name
    ///
    fileprivate lazy var selectedSiteName: String? = {
        ShareExtensionService.retrieveShareExtensionDefaultSite()?.siteName
    }()

    /// Maximum Image Size
    ///
    fileprivate lazy var maximumImageSize: CGSize = {
        let dimension = ShareExtensionService.retrieveShareExtensionMaximumMediaDimension() ?? self.defaultMaxDimension
        return CGSize(width: dimension, height: dimension)
    }()

    /// Tracks Instance
    ///
    fileprivate lazy var tracks: Tracks = {
        Tracks(appGroupName: WPAppGroupName)
    }()

    /// MediaView Instance
    ///
    fileprivate var mediaView: MediaView!

    /// Image Attachment
    ///
    fileprivate var mediaImage: UIImage?

    /// Post's Status
    ///
    fileprivate var postStatus = "publish"

    /// Unique identifier for background sessions
    ///
    fileprivate lazy var backgroundSessionIdentifier: String = {
        let identifier = WPAppGroupName + "." + UUID().uuidString
        return identifier
    }()


    // MARK: - Private Constants

    fileprivate let defaultMaxDimension = 3000
    fileprivate let postStatuses = [
        // TODO: This should eventually be moved into WordPressComKit
        "draft": NSLocalizedString("Draft", comment: "Draft post status"),
        "publish": NSLocalizedString("Publish", comment: "Publish post status")
    ]

    fileprivate enum MediaSettings {
        static let filename = "image.jpg"
        static let mimeType = "image/jpeg"
    }

    // MARK: - UIViewController Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        // Tracker
        tracks.wpcomUsername = wpcomUsername
        title = NSLocalizedString("WordPress", comment: "Application title")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tracks.trackExtensionLaunched(oauth2Token != nil)
        dismissIfNeeded()
    }


    override func beginRequest(with context: NSExtensionContext) {
        super.beginRequest(with: context)
        loadContent(extensionContext: context)
    }


    // MARK: - SLComposeService Overriden Methods

    override func loadPreviewView() -> UIView! {
        return mediaView
    }

    override func isContentValid() -> Bool {
        // Even when the oAuth Token is nil, it's possible the default site hasn't been retrieved yet.
        // Let's disable Post, until the user picks a valid site.
        //
        var validContent = false
        if let extensionContext = extensionContext {
            validContent = ShareExtractor(extensionContext: extensionContext).validContent
        }
        let containsText = contentText.isEmpty == false

        return selectedSiteID != nil && (containsText || validContent)
    }

    override func didSelectCancel() {
        tracks.trackExtensionCancelled()
        super.didSelectCancel()
    }

    override func didSelectPost() {
        guard let _ = oauth2Token, let siteID = selectedSiteID else {
            fatalError("The view should have been dismissed on viewDidAppear!")
        }

        // Save the last used site
        if let siteName = selectedSiteName {
            ShareExtensionService.configureShareExtensionLastUsedSiteID(siteID, lastUsedSiteName: siteName)
        }

        // Proceed uploading the actual post
        let (subject, body) = contentText.stringWithAnchoredLinks().splitContentTextIntoSubjectAndBody()
        if let mediaImage = mediaImage {
            let encodedMedia = mediaImage.resizeWithMaximumSize(maximumImageSize).JPEGEncoded()
            uploadPostWithMedia(subject: subject,
                                body: body,
                                status: postStatus,
                                siteID: siteID,
                                attachedImageData: encodedMedia,
                                requestEnqueued: {
                                    self.tracks.trackExtensionPosted(self.postStatus)
                                    self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            })
        } else {
            uploadPost(subject: subject, body: body, status: postStatus, siteID: siteID, requestEnqueued: {
                self.tracks.trackExtensionPosted(self.postStatus)
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            })
        }
    }

    override func configurationItems() -> [Any]! {
        let blogPickerItem = SLComposeSheetConfigurationItem()!
        blogPickerItem.title = NSLocalizedString("Post to:", comment: "Upload post to the selected Site")
        blogPickerItem.value = selectedSiteName ?? NSLocalizedString("Select a site", comment: "Select a site in the share extension")
        blogPickerItem.tapHandler = { [weak self] in
            self?.displaySitePicker()
        }

        let statusPickerItem = SLComposeSheetConfigurationItem()!
        statusPickerItem.title = NSLocalizedString("Post Status:", comment: "Post status picker title in Share Extension")
        statusPickerItem.value = postStatuses[postStatus]!
        statusPickerItem.tapHandler = { [weak self] in
            self?.displayStatusPicker()
        }

        return [blogPickerItem, statusPickerItem]
    }
}

/// ShareViewController Extension: Encapsulates all of the Action Helpers.
///
private extension ShareViewController {
    func dismissIfNeeded() {
        guard oauth2Token == nil else {
            return
        }

        let title = NSLocalizedString("No WordPress.com Account", comment: "Extension Missing Token Alert Title")
        let message = NSLocalizedString("Launch the WordPress app and log into your WordPress.com or Jetpack site to share.", comment: "Extension Missing Token Alert Title")
        let accept = NSLocalizedString("Cancel Share", comment: "Dismiss Extension and cancel Share OP")

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: accept, style: .default) { (action) in
            self.cancel()
        }

        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }

    func displaySitePicker() {
        let pickerViewController = SitePickerViewController()
        pickerViewController.onChange = { (siteId, description) in
            self.selectedSiteID = siteId
            self.selectedSiteName = description
            self.reloadConfigurationItems()
            self.validateContent()
        }

        pushConfigurationViewController(pickerViewController)
    }

    func displayStatusPicker() {
        let pickerViewController = PostStatusPickerViewController(statuses: postStatuses)
        pickerViewController.onChange = { (status, description) in
            self.postStatus = status
            self.reloadConfigurationItems()
        }

        pushConfigurationViewController(pickerViewController)
    }
}

/// ShareViewController Extension: Encapsulates private helpers
///
private extension ShareViewController {
    func loadContent(extensionContext: NSExtensionContext) {
        ShareExtractor(extensionContext: extensionContext)
            .loadShare { [weak self] share in
                self?.textView.text = share.text

                // Just using the first image for now.
                if let image = share.images.first {
                    self?.imageLoaded(image: image)
                }
        }
    }

    func textLoaded(text: String) {
        var content = ""
        if let contentText = contentText {
            content.append("\(contentText)\n\n")
        }
        content.append(text)
        textView.text = content
    }

    func imageLoaded(image: UIImage) {
        // Load the View
        let mediaView = MediaView()
        mediaView.resizeIfNeededAndDisplay(image)

        // References please
        self.mediaImage = image
        self.mediaView = mediaView
        self.reloadConfigurationItems()
    }
}

/// ShareViewController Extension: Backend Interaction
///
private extension ShareViewController {

    func uploadPost(subject: String, body: String, status: String, siteID: Int, requestEnqueued: @escaping () -> ()) {
        // 15-Nov-2017: Creating a post without media on the PostServiceRemoteREST does not use background uploads so set it false
        let api = WordPressComRestApi(oAuthToken: oauth2Token,
                                      userAgent: nil,
                                      backgroundUploads: false,
                                      backgroundSessionIdentifier: backgroundSessionIdentifier,
                                      sharedContainerIdentifier: WPAppGroupName)
        let remote = PostServiceRemoteREST.init(wordPressComRestApi: api, siteID: NSNumber(value: siteID))
        let remotePost: RemotePost = {
            let post = RemotePost()
            post.siteID = NSNumber(value: siteID)
            post.status = status
            post.title = subject
            post.content = body
            return post
        }()

        remote.createPost(remotePost, success: { post in
            if let post = post {
                DDLogInfo("Post #\(post.postID) was shared.")
            }
            requestEnqueued()
        }, failure: { error in
            if let error = error as NSError? {
                DDLogError("Error creating post in share extension: \(error.localizedDescription)")
                self.tracks.trackExtensionError(error)
            }
            requestEnqueued()
        })
    }

    func uploadPostWithMedia(subject: String, body: String, status: String, siteID: Int, attachedImageData: Data?, requestEnqueued: @escaping () -> ()) {
        guard let attachedImageData = attachedImageData,
            let mediaDirectory = ShareMediaFileManager.shared.mediaUploadDirectoryURL else {
                requestEnqueued()
                return
        }

        let api = WordPressComRestApi(oAuthToken: oauth2Token,
                                      userAgent: nil,
                                      backgroundUploads: true,
                                      backgroundSessionIdentifier: backgroundSessionIdentifier,
                                      sharedContainerIdentifier: WPAppGroupName)
        let remote = PostServiceRemoteREST.init(wordPressComRestApi: api, siteID: NSNumber(value: siteID))
        let remotePost: RemotePost = {
            let post = RemotePost()
            post.siteID = NSNumber(value: siteID)
            post.status = status
            post.title = subject
            post.content = body
            return post
        }()

        let fileName = "image_\(NSDate.timeIntervalSinceReferenceDate).jpg"
        let fullPath = mediaDirectory.appendingPathComponent(fileName)
        let remoteMedia: RemoteMedia = {
            let media = RemoteMedia()
            media.file = MediaSettings.filename
            media.mimeType = MediaSettings.mimeType
            media.localURL = fullPath
            return media
        }()

        do {
            try attachedImageData.write(to: fullPath, options: [.atomic])
        } catch {
            DDLogError("Error saving \(fullPath) to shared container: \(String(describing: error))")
            return
        }

        // NOTE: The success and error closures **may** get called here - it’s non-deterministic as to whether WPiOS
        // or the extension gets the "did complete" callback. So unfortunatly, we need to have the logic to complete
        // post share here as well as WPiOS.
        remote.createPost(remotePost, with: remoteMedia, requestEnqueued: { task in
            requestEnqueued()
        }, success: {_ in
            ShareMediaFileManager.shared.purgeUploadDirectory()
        }) { error in
            guard let error = error as NSError? else {
                return
            }
            DDLogError("Error creating post in share extension: \(error.localizedDescription)")
            self.tracks.trackExtensionError(error)
            ShareMediaFileManager.shared.purgeUploadDirectory()
        }
    }
}
