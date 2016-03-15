import UIKit
import SVProgressHUD
import WordPressShared

/// Implements site management services triggered from SiteSettingsViewController
///
public extension SiteSettingsViewController
{
    /// Presents confirmation alert for Export Content
    ///
    public func confirmExportContent() {
        tableView.deselectSelectedRowWithAnimation(true)

        presentViewController(confirmExportController(), animated: true, completion: nil)
    }

    /// Creates confirmation alert for Export Content
    ///
    private func confirmExportController() -> UIAlertController {
        let confirmTitle = NSLocalizedString("Export Your Content", comment: "Title of Export Content confirmation alert")
        let messageFormat = NSLocalizedString("Your posts, pages, and settings will be mailed to you at %@.", comment: "Message of Export Content confirmation alert; substitution is user's email address")
        let message = String(format: messageFormat, blog.account.email)
        let alertController = UIAlertController(title: confirmTitle, message: message, preferredStyle: .Alert)
        
        let cancelTitle = NSLocalizedString("Cancel", comment: "Alert dismissal title")
        alertController.addCancelActionWithTitle(cancelTitle, handler: nil)
        
        let exportTitle = NSLocalizedString("Export Content", comment: "Export Content confirmation action title")
        alertController.addDefaultActionWithTitle(exportTitle, handler: { _ in
            self.exportContent()
        })
        
        return alertController
    }

    /// Handles triggering content export to XML file via API
    ///
    /// Note: Email is sent on completion
    ///
    private func exportContent() {
        let status = NSLocalizedString("Exporting content…", comment: "Overlay message displayed while starting content export")
        SVProgressHUD.showWithStatus(status, maskType: .Black)
        
        let service = SiteManagementService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.exportContentForBlog(blog,
            success: {
                let status = NSLocalizedString("Email sent!", comment: "Overlay message displayed when export content started")
                SVProgressHUD.showSuccessWithStatus(status)
            },
            failure: { error in
                DDLogSwift.logError("Error exporting content: \(error.localizedDescription)")
                SVProgressHUD.dismiss()
                
                let errorTitle = NSLocalizedString("Export Content Error", comment: "Title of alert when export content fails")
                let alertController = UIAlertController(title: errorTitle, message: error.localizedDescription, preferredStyle: .Alert)

                let okTitle = NSLocalizedString("OK", comment: "Alert dismissal title")
                alertController.addDefaultActionWithTitle(okTitle, handler: nil)
                
                alertController.presentFromRootViewController()
            })
    }    
}
