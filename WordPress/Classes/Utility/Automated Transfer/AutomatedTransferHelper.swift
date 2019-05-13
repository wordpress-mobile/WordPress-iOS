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

        let api = WordPressComRestApi.defaultApi(oAuthToken: token, userAgent: WPUserAgent.wordPress())
        let automatedTransferService = AutomatedTransferService(wordPressComRestApi: api)

        self.site = site
        self.plugin = plugin
        self.automatedTransferService = automatedTransferService
    }

    func automatedTransferConfirmationPrompt() -> UIAlertController {
        let alertController = UIAlertController(title: Constants.PromptMessages.installFirstPluginPrompt,
                                                message: nil,
                                                preferredStyle: .alert)


        alertController.addCancelActionWithTitle(Constants.PromptMessages.alertCancel, handler: { _ in
            WPAnalytics.track(.automatedTransferDialogCancelled)
            DDLogInfo("[AT] User canceled.")
        })
        alertController.addDefaultActionWithTitle(Constants.PromptMessages.alertInstall, handler: { _ in
            DDLogInfo("[AT] User confirmed, proceeding with install.")
            self.startAutomatedTransferProcess()
        })

        DDLogInfo("[AT] Prompting user for confirmation of transfer.")
        return alertController
    }

    func startAutomatedTransferProcess(retryingAfterFailure: Bool = false) {
        DDLogInfo("[AT] Kicking off the AT process.")

        // fake coefficient, just so it doesn't look weird empty!
        SVProgressHUD.showProgress(0.02, status: Constants.PluginNameStrings.progressHudTitle(plugin.name))


        verifyEligibility(retryingAfterFailure: retryingAfterFailure, success: {
                DDLogInfo("[AT] Site was confirmed eligible, proceeding to initiating AT process.")
                self.initiateAutomatedTransfer(retryingAfterFailure: true)
        },
            failure: {
                SVProgressHUD.dismiss()
                ActionDispatcher.dispatch(NoticeAction.post(Notice(title: Constants.PluginNameStrings.genericErrorMessage(self.plugin.name))))
        })
    }

    private func verifyEligibility(retryingAfterFailure: Bool, success: @escaping (() -> ()), failure: @escaping (() -> ())) {
        DDLogInfo("[AT] Starting eligibility check.")

        WPAnalytics.track(.automatedTransferEligibilityCheckInitiated)

        automatedTransferService.checkTransferEligibility(
            siteID: site.siteID,
            success: {
                self.delayWrapper?.delayedRetryAction.cancel()
                self.delayWrapper = nil
                success()
        },
            failure: { (error) in
                DDLogInfo(("[AT] Site ineligible for AT, error: \(error)"))

                let errorMessage: String

                switch error {
                case .unverifiedEmail:
                    errorMessage = Constants.EligibilityErrors.eligibilityUnverifiedEmailError
                case .excessiveDiskSpaceUsage:
                    errorMessage = Constants.EligibilityErrors.eligibilityExcessiveUsageError
                case .noBusinessPlan:
                    errorMessage = Constants.EligibilityErrors.eligibilityNoBusinessPlanError
                case .VIPSite:
                    errorMessage = Constants.EligibilityErrors.eligibilityVIPSitesError
                case .notAdmin:
                    errorMessage = Constants.EligibilityErrors.eligibilityNotAdminError
                case .notDomainOwner:
                    errorMessage = Constants.EligibilityErrors.eligibilityNotDomainOwnerError
                case .noCustomDomain:
                    errorMessage = Constants.EligibilityErrors.eligibilityNoCustomDomainError
                case .greylistedSite:
                    errorMessage = Constants.EligibilityErrors.eligibilityGreyListedError
                case .privateSite:
                    errorMessage = Constants.EligibilityErrors.eligibilityPrivateSiteError
                case .unknown:
                    errorMessage = Constants.EligibilityErrors.eligibilityEligibilityGenericError
                }


                // If the AT process is kicked off *right* after purchasing a domain, it can take
                // a while for the eligiblity check to return a new, correct value.
                // In that case, we want to retry few times until it catches on.
                // Otherwise, let's just fail in the regular way.
                guard retryingAfterFailure else {
                    WPAnalytics.track(.automatedTransferSiteIneligible)
                    SVProgressHUD.dismiss()
                    ActionDispatcher.dispatch(NoticeAction.post(Notice(title: errorMessage)))
                    return
                }

                guard var wrapper = self.delayWrapper else {
                    DDLogInfo("[AT] Eligiblity check failure after purchasing a domain. Scheduling another try.")
                    // This means it's the first retry attempt.

                    let wrapper = DelayStateWrapper(delaySequence: [Constants.afterDomainPurchaseRefreshInterval]) {
                        self.verifyEligibility(retryingAfterFailure: true, success: success, failure: failure)
                    }

                    self.delayWrapper = wrapper
                    return
                }

                DDLogInfo("[AT] Eligibility check retry #\(wrapper.retryAttempt)")
                guard wrapper.retryAttempt < Constants.afterDomainPurchaseMaxRetries else {

                    wrapper.delayedRetryAction.cancel()
                    self.delayWrapper = nil

                    WPAnalytics.track(.automatedTransferSiteIneligible)
                    SVProgressHUD.dismiss()
                    ActionDispatcher.dispatch(NoticeAction.post(Notice(title: errorMessage)))
                    return
                }

                DDLogInfo("[AT] Incrementing eligibility check counter.")
                wrapper.increment()
                self.delayWrapper = wrapper
        })
    }

    private func initiateAutomatedTransfer(retryingAfterFailure: Bool = false) {
        DDLogInfo("[AT] Initiating Automated Transfer.")

        WPAnalytics.track(.automatedTransferInitiate)

        automatedTransferService.initiateAutomatedTransfer(siteID: site.siteID, pluginSlug: plugin.slug, success: { transferID, status in
            self.delayWrapper?.delayedRetryAction.cancel()
            self.delayWrapper = nil

            DDLogInfo("[AT] Succesfully started Automated Transfer process. Transfer ID: \(transferID), status: \(status)")

            WPAnalytics.track(.automatedTransferInitiated)

            // Also an arbitrary number, to show progress. "real progress" should start at 14% (there are currently 7 steps, 100/7 ~= 14).
            SVProgressHUD.showProgress(0.08, status: Constants.PluginNameStrings.progressHudTitle(self.plugin.name))

            // Refresh status after 3 seconds.
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Constants.refreshInterval)) {
                DDLogInfo("[AT] Scheduling status update.")
                self.updateAutomatedTransferStatus()
            }

        }, failure: { (error) in

            // The async nature of AT process bites us here again. Sometimes, even though the backend says
            // 'hell yeah son, everything's fine, go ahead!' in the eligibility check, trying to actually
            // start the AT process (usually only after a custom domain was _just_ purchased) fails spectacularly.
            // In those cases, we'll retry this request a few times.
            guard retryingAfterFailure else {
                DDLogInfo(("[AT] Failed to initiate Automated Transfer: \(error)"))

                WPAnalytics.track(.automatedTransferInitiationFailed)

                SVProgressHUD.dismiss()
                ActionDispatcher.dispatch(NoticeAction.post(Notice(title: Constants.PluginNameStrings.genericErrorMessage(self.plugin.name))))

                return
            }

            guard var wrapper = self.delayWrapper else {
                DDLogInfo("[AT] Kickoff failure after purchasing a domain. Scheduling another try.")
                // This means it's the first retry attempt.

                let wrapper = DelayStateWrapper(delaySequence: [Constants.afterDomainPurchaseRefreshInterval]) {
                    self.initiateAutomatedTransfer(retryingAfterFailure: true)
                }

                self.delayWrapper = wrapper
                return
            }

            DDLogInfo("[AT] Kickoff retry #\(wrapper.retryAttempt)")
            guard wrapper.retryAttempt < Constants.afterDomainPurchaseMaxRetries else {

                wrapper.delayedRetryAction.cancel()
                self.delayWrapper = nil

                DDLogInfo(("[AT] Failed to initiate Automated Transfer: \(error)"))

                WPAnalytics.track(.automatedTransferInitiationFailed)

                SVProgressHUD.dismiss()
                ActionDispatcher.dispatch(NoticeAction.post(Notice(title: Constants.PluginNameStrings.genericErrorMessage(self.plugin.name))))

                return
            }

            DDLogInfo("[AT] Incrementing kickoff  counter.")
            wrapper.increment()
            self.delayWrapper = wrapper

        })
    }

    private func updateAutomatedTransferStatus() {
        // Definining this here, because we also want to be able to call it if we "successfully" fetch a status update
        // and the resulting status is `failed`.
        let failureBlock: ((Error?) -> ()) = { (error) in
            DDLogInfo("[AT] Status update failed: \(String(describing: error))")

            WPAnalytics.track(.automatedTransferStatusFailed)

            SVProgressHUD.dismiss()
            ActionDispatcher.dispatch(NoticeAction.post(Notice(title: Constants.PluginNameStrings.genericErrorMessage(self.plugin.name))))
        }


        automatedTransferService.fetchAutomatedTransferStatus(siteID: site.siteID, success: { (status) in
            DDLogInfo("[AT] Received AT status update: \(status)")

            guard status.status != .error else {
                failureBlock(nil)
                return
            }

            // This means the AT process itself is done. It's now a JP site, so we need to refresh it
            // to make sure we have correct (and latest) data.
            if status.status == .complete {
                DDLogInfo("[AT] AT remote process complete. Refreshing the site.")

                WPAnalytics.track(.automatedTransferStatusComplete)

                SVProgressHUD.showProgress(0.99, status: Constants.PromptMessages.installAlmostDone)
                self.refreshSite()
                return
            }

            if let step = status.step, let totalSteps = status.totalSteps {
                DDLogInfo("[AT] Updating AT progress indicator.")

                let progressFraction = Float(step) / Float(totalSteps)
                SVProgressHUD.showProgress(progressFraction, status: Constants.PluginNameStrings.progressHudTitle(self.plugin.name))
            }


            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Constants.refreshInterval)) {
                DDLogInfo("[AT] Scheduling status update.")
                self.updateAutomatedTransferStatus()
            }
        }, failure: failureBlock)
    }

    private func refreshSite() {
        DDLogInfo("[AT] Starting to refresh the site after AT process completed.")

        let service = BlogService.withMainContext()

        guard let blog = service.blog(byBlogId: site.siteID as NSNumber, andUsername: site.username) else {
            DDLogInfo("[AT] Couldn't find a blog with provided JetpackSiteRef. This definitely shouldn't have happened. Bailing.")

            SVProgressHUD.dismiss()
            ActionDispatcher.dispatch(NoticeAction.post(Notice(title: Constants.PluginNameStrings.genericErrorMessage(self.plugin.name))))
            return
        }

        service.syncBlog(blog, success: {
            DDLogInfo("[AT] Successfully synced the site.")
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
                ActionDispatcher.dispatch(NoticeAction.post(Notice(title: Constants.PluginNameStrings.genericErrorMessage(self.plugin.name))))
                return
            }

            DDLogInfo("[AT] Incrementing retry counter.")
            wrapper.increment()
            self.delayWrapper = wrapper
        })
    }

    private func reloadPlugins() {
        DDLogInfo("[AT] Fetching site plugins.")

        let pluginsRemote = PluginServiceRemote(wordPressComRestApi: automatedTransferService.wordPressComRestApi)
        pluginsRemote.getPlugins(siteID: site.siteID, success: { (plugins) in
            // This was the last step in the process! The transfer is complete. Time to celebrate 🎇🎉✨
            DDLogInfo("[AT] Successfully fetched plugins.")
            DDLogInfo("[AT] AT Process complete.")

            WPAnalytics.track(.automatedTransferFlowComplete)

            ActionDispatcher.dispatch(PluginAction.receivePlugins(site: self.site, plugins: plugins))
            SVProgressHUD.dismiss()
            ActionDispatcher.dispatch(NoticeAction.post(Notice(title: Constants.PluginNameStrings.successMessage(self.plugin.name))))
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
                ActionDispatcher.dispatch(NoticeAction.post(Notice(title: Constants.PluginNameStrings.genericErrorMessage(self.plugin.name))))
                return
            }

            DDLogInfo("[AT] Incrementing retry counter.")
            wrapper.increment()
            self.delayWrapper = wrapper
        })
    }

    private struct Constants {

        struct PromptMessages {
            static let installFirstPluginPrompt = NSLocalizedString("Installing the first plugin on your site can take up to 1 minute. During this time you won’t be able to make changes to your site.", comment: "Message displayed in an alert when user tries to install a first plugin on their site.")
            static let alertCancel = NSLocalizedString("Cancel", comment: "Cancel button.")
            static let alertInstall = NSLocalizedString("Install", comment: "Confirmation button displayd in alert displayed when user installs their first plugin.")
            static let installAlmostDone = NSLocalizedString("We're doing the final setup—almost done…", comment: "Title of progress label displayed when a first plugin on a site is almost done installing.")
        }

        struct EligibilityErrors {
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
        }

        struct PluginNameStrings {
            // Strings that take plugin name in as a parameter.
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

        // Other
        static let refreshInterval: Int = 3
        static let delaySequence = [Constants.refreshInterval]
        static let maxRetries = 10

        static let afterDomainPurchaseRefreshInterval: Int = 10
        static let afterDomainPurchaseMaxRetries = 14
        // It takes a bit longer to issue the SSL certificate for the new domain for AT process. We're more lenient here because of this.
    }


}
