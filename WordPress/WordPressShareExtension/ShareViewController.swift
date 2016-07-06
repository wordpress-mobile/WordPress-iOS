import UIKit
import Social
import WordPressComKit


class ShareViewController: SLComposeServiceViewController {

    // MARK: - Private Properties

    /// WordPress.com Username
    ///
    private lazy var wpcomUsername: String? = {
        ShareExtensionService.retrieveShareExtensionUsername()
    }()

    /// WordPress.com OAuth Token
    ///
    private lazy var oauth2Token: String? = {
        ShareExtensionService.retrieveShareExtensionToken()
    }()

    /// Selected Site's ID
    ///
    private lazy var selectedSiteID: Int? = {
        ShareExtensionService.retrieveShareExtensionPrimarySite()?.siteID
    }()

    /// Selected Site's Name
    ///
    private lazy var selectedSiteName: String? = {
        ShareExtensionService.retrieveShareExtensionPrimarySite()?.siteName
    }()

    /// Maximum Image Size
    ///
    private lazy var maximumImageSize: CGSize = {
        let dimension = ShareExtensionService.retrieveShareExtensionMaximumMediaDimension() ?? self.defaultMaxDimension
        return CGSize(width: dimension, height: dimension)
    }()

    /// Tracks Instance
    ///
    private lazy var tracks: Tracks = {
        Tracks(appGroupName: WPAppGroupName)
    }()

    /// MediaView Instance
    ///
    private var mediaView: MediaView!

    /// Post's Status
    ///
    private var postStatus = "publish"


    // MARK: - Private Constants

    private let defaultMaxDimension = 3000
    private let postStatuses = [
        // TODO: This should eventually be moved into WordPressComKit
        "draft"     : NSLocalizedString("Draft", comment: "Draft post status"),
        "publish"   : NSLocalizedString("Publish", comment: "Publish post status")
    ]



    // MARK: - UIViewController Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        // Tracker
        tracks.wpcomUsername = wpcomUsername
        title = NSLocalizedString("WordPress", comment: "Application title")

        // Initialization
        setupBearerToken()

        // Load TextView + PreviewImage
        loadTextViewContent()
        loadMediaViewContent()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        tracks.trackExtensionLaunched(oauth2Token != nil)
        dismissIfNeeded()
    }



    // MARK: - SLComposeService Overriden Methods

    override func loadPreviewView() -> UIView! {
        return mediaView
    }

    override func isContentValid() -> Bool {
        // Even when the oAuth Token is nil, it's possible the default site hasn't been retrieved yet.
        // Let's disable Post, until the user picks a valid site.
        //
        return selectedSiteID != nil
    }

    override func didSelectCancel() {
        tracks.trackExtensionCancelled()
        super.didSelectCancel()
    }

    override func didSelectPost() {
        guard let _ = oauth2Token, siteID = selectedSiteID else {
            fatalError("The view should have been dismissed on viewDidAppear!")
        }


        // Proceed uploading the actual post
        let (subject, body) = contentText.stringWithAnchoredLinks().splitContentTextIntoSubjectAndBody()
        let attachedImageData = encodedMediaAttachment()
        uploadPostWithSubject(subject, body: body, status: postStatus, siteID: siteID, attachedImageData: attachedImageData) {

// TODO: Handle retry?
            self.tracks.trackExtensionPosted(self.postStatus)
            self.extensionContext?.completeRequestReturningItems([], completionHandler: nil)
        }
    }

    override func configurationItems() -> [AnyObject]! {
        let blogPickerItem = SLComposeSheetConfigurationItem()
        blogPickerItem.title = NSLocalizedString("Post to:", comment: "Upload post to the selected Site")
        blogPickerItem.value = selectedSiteName ?? NSLocalizedString("Select a site", comment: "Select a site in the share extension")
        blogPickerItem.tapHandler = { [weak self] in
            self?.displaySitePicker()
        }

        let statusPickerItem = SLComposeSheetConfigurationItem()
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
private extension ShareViewController
{
    func dismissIfNeeded() {
        guard oauth2Token == nil else {
            return
        }

        let title = NSLocalizedString("No WordPress.com Account", comment: "Extension Missing Token Alert Title")
        let message = NSLocalizedString("Launch the WordPress app and sign into your WordPress.com or Jetpack site to share.", comment: "Extension Missing Token Alert Title")
        let accept = NSLocalizedString("Cancel Share", comment: "Dismiss Extension and cancel Share OP")

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let alertAction = UIAlertAction(title: accept, style: .Default) { (action) in
            self.cancel()
        }

        alertController.addAction(alertAction)
        presentViewController(alertController, animated: true, completion: nil)
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
private extension ShareViewController
{
    func setupBearerToken() {
        guard let bearerToken = oauth2Token else {
            return
        }

        RequestRouter.bearerToken = bearerToken
    }

    func loadTextViewContent() {
        extensionContext?.loadWebsiteUrl { url in
            let current = self.contentText ?? String()
            let source  = url?.absoluteString ?? String()
            let spacing = current.isEmpty ? String() : "\n\n"

            self.textView.text = "\(current)\(spacing)\(source)"
        }
    }

    func loadMediaViewContent() {
        extensionContext?.loadMediaImage { image in
            guard let image = image else {
                return
            }

            self.loadMediaViewFromImage(image)
        }
    }

    func loadMediaViewFromImage(image: UIImage) {
        guard mediaView == nil else {
            assertionFailure()
            return
        }

        mediaView = MediaView()
        mediaView.mediaImage = image
        reloadConfigurationItems()
    }
}



/// ShareViewController Extension: Backend Interaction
///
private extension ShareViewController
{
    func encodedMediaAttachment() -> NSData? {
        let quality = CGFloat(0.9)
        guard let image = mediaView?.mediaImage, payload = UIImageJPEGRepresentation(image, quality) else {
            return nil
        }

        return payload
    }

    func uploadPostWithSubject(subject: String, body: String, status: String, siteID: Int, attachedImageData: NSData?, requestEqueued: Void -> ()) {
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithRandomizedIdentifier()
        let service = PostService(configuration: configuration)
        service.createPost(siteID: siteID, status: status, title: subject, body: body, attachedImageJPEGData: attachedImageData, requestEqueued: {
            requestEqueued()
        }, completion: { (post, error) in
            print("Post \(post) Error \(error)")
        })
    }
}
