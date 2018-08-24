import Foundation
import WordPressFlux

class AutomatedTransferHelper {

    let site: JetpackSiteRef
    let plugin: PluginDirectoryEntry

    let automatedTransferService: AutomatedTransferService

    private var delayWrapper: DelayStateWrapper?

    init?(site: JetpackSiteRef, plugin: PluginDirectoryEntry) {
        DDLogInfo("[AT] Trying to create AutomatedTransferHelper.")

        guard let token = CredentialsService().getOAuthToken(site: site) else {
            DDLogInfo("[AT] Couldn't get credentials for site when creating AutomatedTransferHelper. Bailing.")
            return nil
        }

        let api = WordPressComRestApi(oAuthToken: token, userAgent: WPUserAgent.wordPress())
        let automatedTransferService = AutomatedTransferService(wordPressComRestApi: api)

        self.site = site
        self.plugin = plugin
        self.automatedTransferService = automatedTransferService
    }

    func automatedTransferConfirmationPrompt() -> UIAlertController {
        let alertController = UIAlertController(title: Constants.installFirstPluginPrompt,
                                                message: nil,
                                                preferredStyle: .alert)


        alertController.addCancelActionWithTitle(Constants.alertCancel, handler: { _ in
            DDLogInfo("[AT] User cancelled.")
        })
        alertController.addDefaultActionWithTitle(Constants.alertInstall, handler: { _ in
            DDLogInfo("[AT] User confirmed, proceeding with install.")
            self.kickOffAutomatedTransfer()
        })

        DDLogInfo("[AT] Prompting user for confirmation of transfer.")
        return alertController
    }

    private func kickOffAutomatedTransfer() {
        DDLogInfo("[AT] Kicking off the AT process.")

        // fake coefficient, just so it doesn't look weird empty!
        SVProgressHUD.showProgress(0.02, status: Constants.progressHudTitle(plugin.name))


        verifyEligibility(
            success: {
                DDLogInfo("[AT] Site was confirmed eligible, proceeding to initiating AT process.")
                self.initiateAutomatedTransfer()
        },
            failure: {
                SVProgressHUD.dismiss()
                ActionDispatcher.dispatch(NoticeAction.post(Notice(title: Constants.genericErrorMessage(self.plugin.name))))
        })
    }

    private func verifyEligibility(success: @escaping (() -> ()), failure: @escaping (() -> ())) {
        DDLogInfo("[AT] Starting eligibility check.")

        automatedTransferService.checkTransferEligibility(
            siteID: site.siteID,
            success: {
                DDLogInfo("[AT] Site confirmed eligible.")
                success()
        },
            failure: { (error) in
                DDLogInfo(("[AT] Site ineligible for AT, error: \(error)"))

                let errorMessage: String

                switch error {
                case .unverifiedEmail:
                    errorMessage = Constants.eligibilityUnverifiedEmailError
                case .excessiveDiskSpaceUsage:
                    errorMessage = Constants.eligibilityExcessiveUsageError
                case .noBusinessPlan:
                    errorMessage = Constants.eligibilityNoBusinessPlanError
                case .VIPSite:
                    errorMessage = Constants.eligibilityVIPSitesError
                case .notAdmin:
                    errorMessage = Constants.eligibilityNotAdminError
                case .notDomainOwner:
                    errorMessage = Constants.eligibilityNotDomainOwnerError
                case .noCustomDomain:
                    errorMessage = Constants.eligibilityNoCustomDomainError
                case .greylistedSite:
                    errorMessage = Constants.eligibilityGreyListedError
                case .privateSite:
                    errorMessage = Constants.eligibilityPrivateSiteError
                case .unknown:
                    errorMessage = Constants.eligibilityEligibilityGenericError
                }

                SVProgressHUD.dismiss()
                ActionDispatcher.dispatch(NoticeAction.post(Notice(title: errorMessage)))
        })
    }

    private func initiateAutomatedTransfer() {
        DDLogInfo("[AT] Initiating Automated Transfer.")

        automatedTransferService.initiateAutomatedTransfer(siteID: site.siteID, pluginSlug: plugin.slug, success: { transferID, status in
            DDLogInfo("[AT] Succesfully started Automated Transfer process. Transfer ID: \(transferID), status: \(status)")

            // Also an arbitrary number, to show progress. "real progress" should start at 14% (there are currently 7 steps, 100/7 ~= 14).
            SVProgressHUD.showProgress(0.08, status: Constants.progressHudTitle(self.plugin.name))

            // Refresh status after 3 seconds.
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Constants.refreshInterval)) {
                DDLogInfo("[AT] Scheduling status update.")
                self.updateAutomatedTransferStatus()
            }

        }, failure: { (error) in
            DDLogInfo(("[AT] Failed to initiate Automated Transfer: \(error)"))
            SVProgressHUD.dismiss()
            ActionDispatcher.dispatch(NoticeAction.post(Notice(title: Constants.genericErrorMessage(self.plugin.name))))
        })
    }

    private func updateAutomatedTransferStatus() {
        automatedTransferService.fetchAutomatedTransferStatus(siteID: site.siteID, success: { (status) in
            DDLogInfo("[AT] Received AT status update: \(status)")

            // This means the AT process itself is done. It's now a JP site, so we need to refresh it
            // to make sure we have correct (and latest) data.
            if status.status == .complete {
                DDLogInfo("[AT] AT remote process complete. Refreshing the site.")
                SVProgressHUD.showProgress(0.99, status: Constants.installAlmostDone)
                self.refreshSite()
                return
            }

            if let step = status.step, let totalSteps = status.totalSteps {
                DDLogInfo("[AT] Updating AT progress indicator.")

                let progressFraction = Float(step) / Float(totalSteps)
                SVProgressHUD.showProgress(progressFraction, status: Constants.progressHudTitle(self.plugin.name))
            }


            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Constants.refreshInterval)) {
                DDLogInfo("[AT] Scheduling status update.")
                self.updateAutomatedTransferStatus()
            }
        }, failure: { (error) in
            SVProgressHUD.dismiss()
            ActionDispatcher.dispatch(NoticeAction.post(Notice(title: Constants.genericErrorMessage(self.plugin.name))))
        })
    }

    private func refreshSite() {
        DDLogInfo("[AT] Starting to refresh the site after AT process completed.")

        let service = BlogService.withMainContext()

        guard let blog = service.blog(byBlogId: site.siteID as NSNumber, andUsername: site.username) else {
            DDLogInfo("[AT] Couldn't find a blog with provided JetpackSiteRef. This definitely shouldn't have happened. Bailing.")

            SVProgressHUD.dismiss()
            ActionDispatcher.dispatch(NoticeAction.post(Notice(title: Constants.genericErrorMessage(self.plugin.name))))
            return
        }

        service.syncBlog(blog, success: {
            DDLogInfo("[AT] Sucesfully synced the site.")
            self.delayWrapper = nil

            // after we refreshed the site, we need to manually fetch plugins so the directory/detail screens has correct data.
            self.reloadPlugins()
        }, failure: { (error) in
            DDLogInfo("[AT] Failed to fetch site info, error: \(error)")

            // It's expected for this call to initially fail, due to how JP/AT works.
            // We'll retry for 30 seconds, which should be plenty of time for the site to come back up.
            guard var wrapper = self.delayWrapper else {
                DDLogInfo("[AT] First site fetch failure. Setting up delayed retries.")
                // This means it's the first failure and we need to setup the delayWrapper.

                let wrapper = DelayStateWrapper(delaySequence: Constants.delaySequence) {
                    self.refreshSite()
                }

                self.delayWrapper = wrapper
                return
            }

            DDLogInfo("[AT] Site fetch retry #\(wrapper.retryAttempt)")
            guard wrapper.retryAttempt < Constants.maxRetries else {

                wrapper.delayedRetryAction.cancel()
                self.delayWrapper = nil

                SVProgressHUD.dismiss()
                ActionDispatcher.dispatch(NoticeAction.post(Notice(title: Constants.genericErrorMessage(self.plugin.name))))
                return
            }

            DDLogInfo("[AT] Incrementing retry counter.")
            wrapper.increment()
        })
    }

    private func reloadPlugins() {
        DDLogInfo("[AT] Fetching site plugins.")

        let pluginsRemote = PluginServiceRemote(wordPressComRestApi: automatedTransferService.wordPressComRestApi)
        pluginsRemote.getPlugins(siteID: site.siteID, success: { (plugins) in
            // This was the last step in the process! The transfer is complete. Time to celebrate 🎇🎉✨
            DDLogInfo("[AT] Sucesfully fetched plugins.")
            DDLogInfo("[AT] AT Process complete.")

            ActionDispatcher.dispatch(PluginAction.receivePlugins(site: self.site, plugins: plugins))
            SVProgressHUD.dismiss()
            ActionDispatcher.dispatch(NoticeAction.post(Notice(title: Constants.successMessage(self.plugin.name))))
        }, failure: { (error) in
            DDLogInfo("[AT] Failed to fetch plugins, error: \(error)")

            // Same spiel as with site refresh — it's semi-expected for this call to fail initially.
            guard var wrapper = self.delayWrapper else {
                DDLogInfo("[AT] First plugin fetch failure. Setting up delayed retries.")
                // This means it's the first failure and we need to setup the delayWrapper.

                let wrapper = DelayStateWrapper(delaySequence: Constants.delaySequence) {
                    self.reloadPlugins()
                }

                self.delayWrapper = wrapper
                return
            }

            DDLogInfo("[AT] Plugin fetch retry #\(wrapper.retryAttempt)")
            guard wrapper.retryAttempt < Constants.maxRetries else {

                wrapper.delayedRetryAction.cancel()
                self.delayWrapper = nil

                SVProgressHUD.dismiss()
                ActionDispatcher.dispatch(NoticeAction.post(Notice(title: Constants.genericErrorMessage(self.plugin.name))))
                return
            }

            DDLogInfo("[AT] Incrementing retry counter.")
            wrapper.increment()
        })
    }

    private struct Constants {

        // Prompt messages.
        static let installFirstPluginPrompt = NSLocalizedString("Installing the first plugin on your site can take up to 1 minute.\nDuring this time you won’t be able to make changes to your site.", comment: "Message displayed in an alert when user tries to install a first plugin on their site.")
        static let alertCancel = NSLocalizedString("Cancel", comment: "Cancel button.")
        static let alertInstall = NSLocalizedString("Install", comment: "Confirmation button displayd in alert displayed when user installs their first plugin.")

        // Eligibility errors.
        static let eligibilityUnverifiedEmailError = NSLocalizedString("Plugin feature requires a verified email address.", comment: "Error displayed when trying to install a plugin on a site for the first time.")
        static let eligibilityExcessiveUsageError = NSLocalizedString("Plugin cannot be installed due to disk space limitations.", comment: "Error displayed when trying to install a plugin on a site for the first time.")
        static let eligibilityNoBusinessPlanError = NSLocalizedString("Plugin feature requires a business plan.", comment: "Error displayed when trying to install a plugin on a site for the first time.")
        static let eligibilityVIPSitesError = NSLocalizedString("Plugin cannot be installed on VIP sites.", comment: "Error displayed when trying to install a plugin on a site for the first time.")
        static let eligibilityNotAdminError = NSLocalizedString("Plugin feature requires admin privileges.", comment: "Error displayed when trying to install a plugin on a site for the first time.")
        static let eligibilityNotDomainOwnerError = NSLocalizedString("Plugin feature requires primary domain subscription to be associated with this user.", comment: "Error displayed when trying to install a plugin on a site for the first time.")
        static let eligibilityNoCustomDomainError = NSLocalizedString("Plugin feature requires a custom domain.", comment: "Error displayed when trying to install a plugin on a site for the first time.")
        static let eligibilityGreyListedError = NSLocalizedString("Plugin feature requires the site to be in good standing.", comment: "Error displayed when trying to install a plugin on a site for the first time.")
        static let eligibilityPrivateSiteError = NSLocalizedString("Plugin feature requires the site to be public.", comment: "Error displayed when trying to install a plugin on a site for the first time.")
        static let eligibilityEligibilityGenericError = NSLocalizedString("Plugin feature is not available for this site.", comment: "Error displayed when trying to install a plugin on a site for the first time.")

        // Other
        static let refreshInterval: Int = 3
        static let delaySequence = [Constants.refreshInterval]
        static let maxRetries = 10
        static let installAlmostDone = NSLocalizedString("We're doing the final setup — almost done…", comment: "Title of progress label displayed when a first plugin on a site is almost done installing.")

        // Strings that take a plugin name as a parameter.

        static func progressHudTitle(_ pluginName: String) -> String {
            return String(format: NSLocalizedString("Installing %@…", comment: "Title of a progress view displayed while the first plugin for a site is being installed."), pluginName)
        }

        static func genericErrorMessage(_ pluginName: String) -> String {
            return String(format: NSLocalizedString("Error installing %@.", comment: "Notice displayed after attempt to install a plugin fails."), pluginName)
        }

        static func successMessage(_ pluginName: String) -> String {
            return String(format: NSLocalizedString("Successfully installed %@.", comment: "Notice displayed after installing a plug-in."), pluginName)
        }
    }


}
