import UIKit
import WordPressComAnalytics

/// A protocol and extension encapsulating syncing behavior common to WPCom
/// signin controllers.  Responsible for syncing account information and blog
/// details of the user.
///
protocol SigninWPComSyncHandler: class {
    func configureViewLoading(_ loading: Bool)
    func configureStatusLabel(_ message: String)
    func dismiss()
    func displayError(_ error: NSError, sourceTag: SupportSourceTag)
    func updateSafariCredentialsIfNeeded()

    func syncWPCom(_ username: String, authToken: String, requiredMultifactor: Bool)
    func handleSyncSuccess(_ requiredMultifactor: Bool)
    func handleSyncFailure(_ error: NSError?)
}


extension SigninWPComSyncHandler {

    /// Syncs account and blog information for the authenticated wpcom user.
    ///
    /// - Parameters:
    ///     - username: The username.
    ///     - authToken: The authentication token.
    ///     - requiredMultifactor: Whether a multifactor code was required while authenticating.
    ///
    func syncWPCom(_ username: String, authToken: String, requiredMultifactor: Bool) {
        updateSafariCredentialsIfNeeded()

        configureStatusLabel(NSLocalizedString("Getting account information", comment: "Alerts the user that wpcom account information is being retrieved."))

        let accountFacade = AccountServiceFacade()
        let account = accountFacade.createOrUpdateWordPressComAccount(withUsername: username, authToken: authToken)
        accountFacade.setDefaultWordPressComAccount(account)

        BlogSyncFacade().syncBlogs(for: account, success: { [weak self] in
                accountFacade.updateUserDetails(for: account, success: { [weak self] in
                self?.handleSyncSuccess(requiredMultifactor)

                }, failure: { [weak self] (error: Error?) in
                    self?.handleSyncFailure(error as NSError?)
                })

            }, failure: { [weak self] (error: Error?) in
                self?.handleSyncFailure(error as NSError?)
            })
    }


    /// Cleans up the view after a successful sync and dismisses the NUX controller.
    /// - Parameter requiredMultifactor: Whether a multifactor code was required while authenticating.
    ///
    /// - Parameters:
    ///
    func handleSyncSuccess(_ requiredMultifactor: Bool) {
        configureStatusLabel("")
        configureViewLoading(false)

        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: SigninHelpers.WPSigninDidFinishNotification), object: nil)

        dismiss()

        let properties = [
            "multifactor": requiredMultifactor ? true.description : false.description,
            "dotcom_user": true.description
        ]

        WPAppAnalytics.track(WPAnalyticsStat.signedIn, withProperties: properties)
    }


    /// Handles an error while syncing account and blog information for the
    /// authenticated user.
    ///
    func handleSyncFailure(_ error: NSError?) {
        configureStatusLabel("")
        configureViewLoading(false)

        // At this point the user is authed and there is a valid account in core data.
        // Make a note of the error and just dismiss the vc. There might be some
        // wonkiness due to missing data (blogs, account info) but this will eventually
        // resync.
        DDLogSwift.logError("Error while syncing wpcom account and/or blog details after authentiating. \(String(describing: error))")
        dismiss()
    }

}
