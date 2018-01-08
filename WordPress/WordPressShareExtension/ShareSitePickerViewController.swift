import UIKit
import WordPressShared
import WordPressKit

class ShareSitePickerViewController: ShareExtensionAbstractViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var modulesTableView: UITableView!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var sitePickerTableView: UITableView!
    @IBOutlet weak var modulesTableViewHeightConstraint: NSLayoutConstraint!
    var modules = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        modulesTableView.delegate = self
        modulesTableView.dataSource = self
        modulesTableView.backgroundColor = UIColor.blue
        modules = ["Featured Image", "Category", "Tags"]
        modulesTableViewHeightConstraint.constant = 400
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modules.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ModuleTableCell", for: indexPath)
        
        cell.textLabel!.text = modules[indexPath.row]
        cell.detailTextLabel!.text = "yup"
        
        return cell
    }
}

// MARK: - Misc Private helpers

private extension ShareSitePickerViewController {
    func savePostToRemoteSite() {
        guard let _ = oauth2Token, let siteID = selectedSiteID else {
            fatalError("Need to have an oauth token and site ID selected.")
        }

        // FIXME: Save the last used site
        //        if let siteName = selectedSiteName {
        //            ShareExtensionService.configureShareExtensionLastUsedSiteID(siteID, lastUsedSiteName: siteName)
        //        }

        // Proceed uploading the actual post
        if shareData.sharedImageDict.values.count > 0 {
            uploadPostWithMedia(subject: shareData.title,
                                body: shareData.contentBody,
                                status: shareData.postStatus,
                                siteID: siteID,
                                requestEnqueued: {
                                    self.tracks.trackExtensionPosted(self.shareData.postStatus)
                                    self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            })
        } else {
            let remotePost: RemotePost = {
                let post = RemotePost()
                post.siteID = NSNumber(value: siteID)
                post.status = shareData.postStatus
                post.title = shareData.title
                post.content = shareData.contentBody
                return post
            }()
            let uploadPostOpID = coreDataStack.savePostOperation(remotePost, groupIdentifier: groupIdentifier, with: .inProgress)
            uploadPost(forUploadOpWithObjectID: uploadPostOpID, requestEnqueued: {
                self.tracks.trackExtensionPosted(self.shareData.postStatus)
                self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            })
        }
    }
}
