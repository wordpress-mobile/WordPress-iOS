import UIKit
import WordPressComAnalytics

/// A protocol and extension encapsulating syncing behavior common to WPCom
/// signin controllers.  Responsible for syncing account information and blog
/// details of the user.
///
protocol SigninWPComSyncHandler: class
{
    func configureViewLoading(loading: Bool)
    func configureStatusLabel(message: String)
    func dismiss()
    func displayError(error: NSError)
    func updateSafariCredentialsIfNeeded()

    func syncWPCom(username: String, authToken: String, requiredMultifactor: Bool)
    func handleSyncSuccess(requiredMultifactor: Bool)
    func handleSyncFailure(error: NSError)
}


extension SigninWPComSyncHandler
{

    /// Syncs account and blog information for the authenticated wpcom user.
    ///
    /// - Parameters:
    ///     - username: The username.
    ///     - authToken: The authentication token.
    ///     - requiredMultifactor: Whether a multifactor code was required while authenticating.
    ///
    func syncWPCom(username: String, authToken: String, requiredMultifactor: Bool) {
        updateSafariCredentialsIfNeeded()

        configureStatusLabel(NSLocalizedString("Getting account information", comment:"Alerts the user that wpcom account information is being retrieved."))

        let accountFacade = AccountServiceFacade()
        let account = accountFacade.createOrUpdateWordPressComAccountWithUsername(username, authToken: authToken)
        accountFacade.setDefaultWordPressComAccount(account)

        BlogSyncFacade().syncBlogsForAccount(account, success: { [weak self] in
                accountFacade.updateUserDetailsForAccount(account, success: { [weak self] in

                self?.handleSyncSuccess(requiredMultifactor)

                }, failure: { [weak self] (error: NSError!) in
                    self?.handleSyncFailure(error)
                })

            }, failure: { [weak self] (error: NSError!) in
                self?.handleSyncFailure(error)
            })
    }


    /// Cleans up the view after a successful sync and dismisses the NUX controller.
    /// - Parameter requiredMultifactor: Whether a multifactor code was required while authenticating.
    ///
    /// - Parameters:
    ///
    func handleSyncSuccess(requiredMultifactor: Bool) {
        configureStatusLabel("")
        configureViewLoading(false)
        dismiss()

        let properties = [
            "multifactor": String(Int(requiredMultifactor)),
            "dotcom_user": "1"
        ]

        OptimizelyHelper.trackLoggedIn()
        WPAppAnalytics.track(WPAnalyticsStat.SignedIn, withProperties: properties)
    }


    /// Handles an error while syncing account and blog information for the
    /// authenticated user.
    ///
    func handleSyncFailure(error: NSError) {
        configureStatusLabel("")
        configureViewLoading(false)

        // At this point the user is authed and there is a valid account in core data.
        // Make a note of the error and just dismiss the vc. There might be some
        // wonkiness due to missing data (blogs, account info) but this will eventually
        // resync.
        DDLogSwift.logError("Error while syncing wpcom account and/or blog details after authentiating. \(error)")
        dismiss()
    }

}
