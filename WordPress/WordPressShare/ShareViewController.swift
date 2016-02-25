import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {
    private var oauth2Token: NSString?
    private var selectedSiteID: Int?
    private var selectedSiteName: String?
    private var postStatus = "publish"
    
    override func viewDidLoad() {
        let authDetails = ShareExtensionService.retrieveShareExtensionConfiguration()
        oauth2Token = authDetails?.oauth2Token
        selectedSiteID = authDetails?.defaultSiteID
        selectedSiteName = authDetails?.defaultSiteName
    }
    
    // MARK: - UIViewController Methods
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        dismissIfNeeded()
    }
    
    // MARK: - Private Helpers
    private func dismissIfNeeded() {
        guard oauth2Token == nil else {
            return
        }
        
        let title = NSLocalizedString("No WordPress.com Account", comment: "Extension Missing Token Alert Title")
        let message = NSLocalizedString("Launch the WordPress app and sign into your WordPress.com or Jetpack site to share.", comment: "Extension Missing Token Alert Title")
        let accept = NSLocalizedString("Cancel Share", comment: "")
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let alertAction = UIAlertAction(title: accept, style: .Default) { (action: UIAlertAction) -> Void in
            self.cancel()
        }
        
        alertController.addAction(alertAction)
        presentViewController(alertController, animated: true, completion: nil)
    }

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
    }

    override func configurationItems() -> [AnyObject]! {
        let blogPickerItem = SLComposeSheetConfigurationItem()
        blogPickerItem.title = NSLocalizedString("Post to:", comment: "Upload post to the selected Site")
        blogPickerItem.value = selectedSiteName ?? NSLocalizedString("Select a site", comment: "Select a site in the share extension")
        blogPickerItem.tapHandler = { [weak self] in
            self?.displayBlogPicker()
        }
        
        let statusPickerItem = SLComposeSheetConfigurationItem()
        statusPickerItem.title = NSLocalizedString("Post Status:", comment: "Post status picker title in Share Extension")
        statusPickerItem.value = self.postStatuses[postStatus]!
        statusPickerItem.tapHandler = { [weak self] in
            self?.displayStatusPicker()
        }
        
        return [blogPickerItem, statusPickerItem]
    }

    
    private func displayBlogPicker() {
        let pickerViewController = BlogPickerViewController()
        pickerViewController.onChange = { (siteId, description) in
            print("New siteId \(siteId) description \(description)")
            self.selectedSiteID = siteId
            self.selectedSiteName = description
            self.reloadConfigurationItems()
        }
        
        pushConfigurationViewController(pickerViewController)
    }
    
    private func displayStatusPicker() {
        let pickerViewController = PostStatusPickerViewController()
        pickerViewController.statuses = postStatuses
        pickerViewController.onChange = { (status, description) in
            print("New post status \(status) description \(description)")
            self.postStatus = status
            self.reloadConfigurationItems()
        }
        
        pushConfigurationViewController(pickerViewController)
    }
    
    private let postStatuses = [
        "draft" : NSLocalizedString("Draft", comment: "Draft post status"),
        "publish" : NSLocalizedString("Publish", comment: "Publish post status")]

}
