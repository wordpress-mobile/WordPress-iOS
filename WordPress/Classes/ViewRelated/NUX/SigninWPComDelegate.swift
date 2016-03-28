import UIKit
import WordPressComAnalytics

protocol SigninWPComDelegate: class
{
    func configureLoading(loading: Bool)
    func configureStatusMessage(message: String)
    func dismiss()
    func displayError(error: NSError)
    func updateSafariCredentialsIfNeeded()

    func syncWPCom(username: String, authToken: String, requiredMultifactor: Bool)
    func handleSyncSuccess(requiredMultifactor: Bool)
    func handleSyncFailure(error: NSError)
}


extension SigninWPComDelegate
{

    ///
    ///
    func syncWPCom(username: String, authToken: String, requiredMultifactor: Bool) {
        updateSafariCredentialsIfNeeded()

// TODO: self.shouldReauthenticateDefaultAccount / [self.accountServiceFacade removeLegacyAccount:username];

        configureStatusMessage(NSLocalizedString("Getting account information", comment:"Alerts the user that wpcom account information is being retrieved."));

        let accountFacade = AccountServiceFacade()
        let account = accountFacade.createOrUpdateWordPressComAccountWithUsername(username, authToken: authToken)
        accountFacade.updateUserDetailsForAccount(account, success: { [weak self] in

            BlogSyncFacade().syncBlogsForAccount(account, success: { [weak self] in
                self?.handleSyncSuccess(requiredMultifactor)

                }, failure: { [weak self] (error: NSError!) in
                    self?.handleSyncFailure(error)
                })

            }, failure: { [weak self] (error: NSError!) in
                self?.handleSyncFailure(error)
            })
    }


    ///
    ///
    func handleSyncSuccess(requiredMultifactor: Bool) {
        configureStatusMessage("")
        configureLoading(false)
        dismiss()

        let properties = [
            "multifactor": "\(Int(requiredMultifactor))",
            "dotcom_user": "1"
        ]

        WPAppAnalytics.track(WPAnalyticsStat.SignedIn, withProperties: properties)
    }


    ///
    ///
    func handleSyncFailure(error: NSError) {
        configureStatusMessage("")
        configureLoading(false)
        displayError(error)
    }

}
