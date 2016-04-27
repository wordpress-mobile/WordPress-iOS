import UIKit
import Social
import WordPressComKit


class ShareViewController: SLComposeServiceViewController {
    // MARK: - Private Properties
    private var wpcomUsername: String?
    private var oauth2Token: NSString?
    private var selectedSiteID: Int?
    private var selectedSiteName: String?
    private var postStatus = "publish"
    private var tracks: Tracks!
    
    
    // MARK: - UIViewController Methods
    override func viewDidLoad() {
        // Retrieve all of the settings
        let username = ShareExtensionService.retrieveShareExtensionUsername()
        let token = ShareExtensionService.retrieveShareExtensionToken()
        let defaultSite = ShareExtensionService.retrieveShareExtensionPrimarySite()
        
        // Properties
        wpcomUsername = username
        oauth2Token = token
        selectedSiteID = defaultSite?.siteID
        selectedSiteName = defaultSite?.siteName

        // Tracker
        tracks = Tracks(appGroupName: WPAppGroupName)
        tracks.wpcomUsername = username

        // TextView
        loadTextViewContent()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tracks.trackExtensionLaunched(oauth2Token != nil)
        dismissIfNeeded()
    }
    
    
    
    // MARK: - Overriden Methods
    override func loadPreviewView() -> UIView! {
        // Hides Composer Thumbnail Preview.
        return UIView()
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
        RequestRouter.bearerToken = oauth2Token! as String

        let identifier = WPAppGroupName + "." + NSUUID().UUIDString
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(identifier)
        configuration.sharedContainerIdentifier = WPAppGroupName
        
        let service = PostService(configuration: configuration)
        let (subject, body) = splitContentTextIntoSubjectAndBody(contentText)
        
        service.createPost(siteID: selectedSiteID!, status: postStatus, title: subject, body: body) {
            (post, error) in
            print("Post \(post) Error \(error)")
        }
        
        extensionContext?.completeRequestReturningItems([], completionHandler: nil)
        
        tracks.trackExtensionPosted(postStatus)
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

    
    
    // MARK: - Private Helpers
    private func dismissIfNeeded() {
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
    
    private func displaySitePicker() {
        let pickerViewController = SitePickerViewController()
        pickerViewController.onChange = { (siteId, description) in
            self.selectedSiteID = siteId
            self.selectedSiteName = description
            self.reloadConfigurationItems()
            self.validateContent()
        }
        
        pushConfigurationViewController(pickerViewController)
    }
    
    private func displayStatusPicker() {
        let pickerViewController = PostStatusPickerViewController(statuses: postStatuses)
        pickerViewController.onChange = { (status, description) in
            self.postStatus = status
            self.reloadConfigurationItems()
        }
        
        pushConfigurationViewController(pickerViewController)
    }
    
    private func loadTextViewContent() {
        extensionContext?.loadWebsiteUrl { url in
            dispatch_async(dispatch_get_main_queue()) {
                let current = self.contentText ?? String()
                let source  = url?.absoluteString ?? String()
                
                self.textView.text = "\(current)\n\n\(source)"
            }
        }
    }

    
    // TODO: This should eventually be moved into WordPressComKit
    private let postStatuses = [
        "draft" : NSLocalizedString("Draft", comment: "Draft post status"),
        "publish" : NSLocalizedString("Publish", comment: "Publish post status")]

    private func splitContentTextIntoSubjectAndBody(contentText: String) -> (subject: String, body: String) {
        let fullText = contentText
        let indexOfFirstNewline = fullText.rangeOfCharacterFromSet(NSCharacterSet.newlineCharacterSet())
        let firstLineOfText = indexOfFirstNewline != nil ? fullText.substringToIndex(indexOfFirstNewline!.startIndex) : fullText
        let restOfText = indexOfFirstNewline != nil ? fullText.substringFromIndex(indexOfFirstNewline!.endIndex) : ""

        return (firstLineOfText, restOfText)
    }
}
