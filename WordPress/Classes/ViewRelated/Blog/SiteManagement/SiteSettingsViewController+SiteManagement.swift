import UIKit
import SVProgressHUD
import WordPressShared

/// Implements site management services triggered from SiteSettingsViewController
///
public extension SiteSettingsViewController {

    /// Presents confirmation alert for Export Content
    ///
    public func confirmExportContent() {
        tableView.deselectSelectedRowWithAnimation(true)

        WPAppAnalytics.track(.siteSettingsExportSiteAccessed, with: self.blog)
        present(confirmExportController(), animated: true, completion: nil)
    }

    /// Creates confirmation alert for Export Content
    ///
    /// - Returns: UIAlertController
    ///
    fileprivate func confirmExportController() -> UIAlertController {
        let confirmTitle = NSLocalizedString("Export Your Content", comment: "Title of Export Content confirmation alert")
        let messageFormat = NSLocalizedString("Your posts, pages, and settings will be mailed to you at %@.", comment: "Message of Export Content confirmation alert; substitution is user's email address")
        let message = String(format: messageFormat, blog.account!.email)
        let alertController = UIAlertController(title: confirmTitle, message: message, preferredStyle: .alert)

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
    fileprivate func exportContent() {
        let status = NSLocalizedString("Exporting content…", comment: "Overlay message displayed while starting content export")
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.show(withStatus: status)

        let trackedBlog = blog
        WPAppAnalytics.track(.siteSettingsExportSiteRequested, with: trackedBlog)
        let service = SiteManagementService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.exportContentForBlog(blog,
            success: {
                WPAppAnalytics.track(.siteSettingsExportSiteResponseOK, with: trackedBlog)
                let status = NSLocalizedString("Email sent!", comment: "Overlay message displayed when export content started")
                SVProgressHUD.showDismissableSuccess(withStatus: status)
            },
            failure: { error in
                DDLogSwift.logError("Error exporting content: \(error.localizedDescription)")
                WPAppAnalytics.track(.siteSettingsExportSiteResponseError, with: trackedBlog)
                SVProgressHUD.dismiss()

                let errorTitle = NSLocalizedString("Export Content Error", comment: "Title of alert when export content fails")
                let alertController = UIAlertController(title: errorTitle, message: error.localizedDescription, preferredStyle: .alert)

                let okTitle = NSLocalizedString("OK", comment: "Alert dismissal title")
                _ = alertController.addDefaultActionWithTitle(okTitle, handler: nil)

                alertController.presentFromRootViewController()
            })
    }

    /// Requests site purchases to determine whether site is deletable
    ///
    public func checkSiteDeletable() {
        tableView.deselectSelectedRowWithAnimation(true)

        let status = NSLocalizedString("Checking purchases…", comment: "Overlay message displayed while checking if site has premium purchases")
        SVProgressHUD.show(withStatus: status)

        WPAppAnalytics.track(.siteSettingsDeleteSitePurchasesRequested, with: blog)
        let service = SiteManagementService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.getActivePurchasesForBlog(blog,
            success: { [weak self] purchases in
                SVProgressHUD.dismiss()
                guard let strongSelf = self else {
                    return
                }

                if purchases.isEmpty {
                    WPAppAnalytics.track(.siteSettingsDeleteSiteAccessed, with: strongSelf.blog)
                    strongSelf.navigationController?.pushViewController(DeleteSiteViewController.controller(strongSelf.blog), animated: true)
                } else {
                    WPAppAnalytics.track(.siteSettingsDeleteSitePurchasesShown, with: strongSelf.blog)
                    strongSelf.present(strongSelf.warnPurchasesController(), animated: true, completion: nil)
                }
            },
            failure: { error in
                DDLogSwift.logError("Error getting purchases: \(error.localizedDescription)")
                SVProgressHUD.dismiss()

                let errorTitle = NSLocalizedString("Check Purchases Error", comment: "Title of alert when getting purchases fails")
                let alertController = UIAlertController(title: errorTitle, message: error.localizedDescription, preferredStyle: .alert)

                let okTitle = NSLocalizedString("OK", comment: "Alert dismissal title")
                alertController.addDefaultActionWithTitle(okTitle, handler: nil)

                alertController.presentFromRootViewController()
            })
    }

    /// Creates purchase warning alert for Delete Site
    ///
    /// - Returns: UIAlertController
    ///
    fileprivate func warnPurchasesController() -> UIAlertController {
        let warnTitle = NSLocalizedString("Premium Upgrades", comment: "Title of alert when attempting to delete site with purchases")
        let message = NSLocalizedString("You have active premium upgrades on your site. Please cancel your upgrades prior to deleting your site.", comment: "Message alert when attempting to delete site with purchases")
        let alertController = UIAlertController(title: warnTitle, message: message, preferredStyle: .alert)

        let cancelTitle = NSLocalizedString("Cancel", comment: "Alert dismissal title")
        alertController.addCancelActionWithTitle(cancelTitle, handler: nil)

        let showTitle = NSLocalizedString("Show Purchases", comment: "Show site purchases action title")
        alertController.addDefaultActionWithTitle(showTitle, handler: { _ in
            WPAppAnalytics.track(.siteSettingsDeleteSitePurchasesShowClicked, with: self.blog)
            self.showPurchases()
        })

        return alertController
    }

    /// Brings up web interface showing site purchases for cancellation
    ///
    fileprivate func showPurchases() {
        let purchasesUrl = "https://wordpress.com/purchases"

        let controller = WPWebViewController()
        controller.authToken = blog.authToken
        controller.username = blog.usernameForSite
        controller.password = blog.password
        controller.wpLoginURL = URL(string: blog.loginUrl())
        controller.secureInteraction = true
        controller.url = URL(string: purchasesUrl)
        controller.loadViewIfNeeded()
        controller.navigationItem.titleView = nil
        controller.title = NSLocalizedString("Purchases", comment: "Title of screen showing site purchases")

        navigationController?.pushViewController(controller, animated: true)
    }
}
