import UIKit
import Social
import WordPressComKit


class ShareViewController: SLComposeServiceViewController {

    // MARK: - Private Properties

    private lazy var wpcomUsername: String? = {
        ShareExtensionService.retrieveShareExtensionUsername()
    }()

    private lazy var oauth2Token: String? = {
        ShareExtensionService.retrieveShareExtensionToken()
    }()

    private lazy var selectedSiteID: Int? = {
        ShareExtensionService.retrieveShareExtensionPrimarySite()?.siteID
    }()

    private lazy var selectedSiteName: String? = {
        ShareExtensionService.retrieveShareExtensionPrimarySite()?.siteName
    }()

    private var mediaView: MediaView!

    private lazy var tracks: Tracks = {
        Tracks(appGroupName: WPAppGroupName)
    }()

    private var postStatus = "publish"



    // TODO: This should eventually be moved into WordPressComKit
    private let postStatuses = [
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

        // Upload Media, if any
        uploadImageIfNeeded(mediaView?.mediaImage, siteID: siteID) { media in
            // Proceed uploading the actual post
            var (subject, body) = self.contentText.stringWithAnchoredLinks().splitContentTextIntoSubjectAndBody()

            if let mediaURL = media?.remoteURL {
                body = body.stringByPrependingMediaURL(mediaURL)
            }
            self.uploadPostWithSubject(subject, body: body, status: self.postStatus, siteID: siteID)

// TODO: Handle retry?
        }

        tracks.trackExtensionPosted(postStatus)
        extensionContext?.completeRequestReturningItems([], completionHandler: nil)
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
    func uploadImageIfNeeded(image: UIImage?, siteID: Int, completion: Media? -> ()) {
        guard let image = image, payload = UIImagePNGRepresentation(image) else {
            completion(nil)
            return
        }

        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithRandomizedIdentifier()
        let service = MediaService(configuration: configuration)

        service.createMedia(payload, filename: MediaSettings.filename, mimeType: MediaSettings.mimeType, siteID: siteID) { (media, error) in
            NSLog("Media: \(media) Error: \(error)")
            completion(media)
        }
    }

    func uploadPostWithSubject(subject: String, body: String, status: String, siteID: Int) {
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithRandomizedIdentifier()
        let service = PostService(configuration: configuration)
        service.createPost(siteID: siteID, status: status, title: subject, body: body) { (post, error) in
            print("Post \(post) Error \(error)")
        }
    }


    enum MediaSettings {
        static let filename = "image.png"
        static let mimeType = "image/png"
    }
}
