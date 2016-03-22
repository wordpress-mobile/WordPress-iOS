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
    /// - Returns: UIAlertController
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
    /// - Note: Email is sent on completion
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

    /// Requests site purchases to determine whether site is deletable
    ///
    public func checkSiteDeletable() {
        tableView.deselectSelectedRowWithAnimation(true)
        
        let status = NSLocalizedString("Checking purchases…", comment: "Overlay message displayed while checking if site has premium purchases")
        SVProgressHUD.showWithStatus(status)

        let service = SiteManagementService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.getActivePurchasesForBlog(blog,
            success: { [weak self] purchases in
                SVProgressHUD.dismiss()
                guard let strongSelf = self else {
                    return
                }
                
                let alertController = purchases.isEmpty ? strongSelf.confirmDeleteController() : strongSelf.warnPurchasesController()
                strongSelf.presentViewController(alertController, animated: true, completion: nil)
            },
            failure: { error in
                DDLogSwift.logError("Error getting purchases: \(error.localizedDescription)")
                SVProgressHUD.dismiss()
                
                let errorTitle = NSLocalizedString("Check Purchases Error", comment: "Title of alert when getting purchases fails")
                let alertController = UIAlertController(title: errorTitle, message: error.localizedDescription, preferredStyle: .Alert)
                
                let okTitle = NSLocalizedString("OK", comment: "Alert dismissal title")
                alertController.addDefaultActionWithTitle(okTitle, handler: nil)
                
                alertController.presentFromRootViewController()
            })
    }
    
    /// Creates confirmation alert for Delete Site
    ///
    /// - Returns: UIAlertController
    ///
    private func confirmDeleteController() -> UIAlertController {
        let confirmTitle = NSLocalizedString("Confirm Delete Site", comment: "Title of Delete Site confirmation alert")
        let messageFormat = NSLocalizedString("Please type in \n\n%@\n\n in the field below to confirm. Your site will then be gone forever.", comment: "Message of Delete Site confirmation alert; substitution is site's host")
        let message = String(format: messageFormat, blog.displayURL!)
        let alertController = UIAlertController(title: confirmTitle, message: message, preferredStyle: .Alert)
        
        let cancelTitle = NSLocalizedString("Cancel", comment: "Alert dismissal title")
        alertController.addCancelActionWithTitle(cancelTitle, handler: nil)
        
        let deleteTitle = NSLocalizedString("Delete this site", comment: "Delete Site confirmation action title")
        let deleteAction = UIAlertAction(title: deleteTitle, style: .Destructive, handler: { action in
            self.deleteSiteConfirmed()
        })
        deleteAction.enabled = false
        alertController.addAction(deleteAction)
        
        alertController.addTextFieldWithConfigurationHandler({ textField in
            textField.addTarget(self, action: #selector(SiteSettingsViewController.alertTextFieldDidChange(_:)), forControlEvents: .EditingChanged)
        })
        
        return alertController
    }
    
    /// Verifies site address as password for Delete Site
    ///
    func alertTextFieldDidChange(sender: UITextField) {
        guard let deleteAction = (presentedViewController as? UIAlertController)?.actions.last else {
            return
        }
        
        let prompt = blog.displayURL?.lowercaseString.trim()
        let password = sender.text?.lowercaseString.trim()
        deleteAction.enabled = prompt == password
    }

    /// Handles deletion of the blog's site and all content from WordPress.com
    ///
    /// - Note: This is permanent and cannot be reversed by user
    ///
    private func deleteSiteConfirmed() {
        let status = NSLocalizedString("Deleting site…", comment: "Overlay message displayed while deleting site")
        SVProgressHUD.showWithStatus(status, maskType: .Black)
        
        let service = SiteManagementService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.deleteSiteForBlog(blog,
            success: { [weak self] in
                let status = NSLocalizedString("Site deleted", comment: "Overlay message displayed when site successfully deleted")
                SVProgressHUD.showSuccessWithStatus(status)
                
                if let navController = self?.navigationController {
                    navController.popToRootViewControllerAnimated(true)
                }
            },
            failure: { error in
                DDLogSwift.logError("Error deleting site: \(error.localizedDescription)")
                SVProgressHUD.dismiss()
                
                let errorTitle = NSLocalizedString("Delete Site Error", comment: "Title of alert when site deletion fails")
                let alertController = UIAlertController(title: errorTitle, message: error.localizedDescription, preferredStyle: .Alert)
                
                let okTitle = NSLocalizedString("OK", comment: "Alert dismissal title")
                alertController.addDefaultActionWithTitle(okTitle, handler: nil)
                
                alertController.presentFromRootViewController()
            })
    }
    
    /// Creates purchase warning alert for Delete Site
    ///
    /// - Returns: UIAlertController
    ///
    private func warnPurchasesController() -> UIAlertController {
        let warnTitle = NSLocalizedString("Premium Upgrades", comment: "Title of alert when attempting to delete site with purchases")
        let message = NSLocalizedString("You have active premium upgrades on your site. Please cancel your upgrades prior to deleting your site.", comment: "Message alert when attempting to delete site with purchases")
        let alertController = UIAlertController(title: warnTitle, message: message, preferredStyle: .Alert)
        
        let cancelTitle = NSLocalizedString("Cancel", comment: "Alert dismissal title")
        alertController.addCancelActionWithTitle(cancelTitle, handler: nil)
        
        let showTitle = NSLocalizedString("Show Purchases", comment: "Show site purchases action title")
        alertController.addDefaultActionWithTitle(showTitle, handler: { _ in
            self.showPurchases()
        })
        
        return alertController
    }
    
    /// Brings up web interface showing site purchases for cancellation
    ///
    private func showPurchases() {
        let purchasesUrl = "https://wordpress.com/purchases"
        
        let controller = WPWebViewController()
        controller.authToken = blog.authToken;
        controller.username = blog.usernameForSite;
        controller.password = blog.password;
        controller.wpLoginURL = NSURL(string: blog.loginUrl())
        controller.secureInteraction = true
        controller.url = NSURL(string: purchasesUrl)
        controller.loadViewIfNeeded()
        controller.navigationItem.titleView = nil
        controller.title = NSLocalizedString("Purchases", comment: "Title of screen showing site purchases")
       
        navigationController?.pushViewController(controller, animated:true)
    }
}
