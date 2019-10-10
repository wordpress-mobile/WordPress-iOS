import Foundation
import WordPressShared


/// KeyringAccount is used to normalize the list of avaiable accounts while
/// preserving the owning keyring connection.
///
struct KeyringAccount {
    var name: String // The account name
    var externalID: String? // The actual externalID value that should be passed when creating/updating a publicize connection.
    var externalIDForConnection: String // The effective external ID that should be used for comparing a keyring account with a PublicizeConnection.
    var keyringConnection: KeyringConnection
}

@objc class KeyringAccountHelper: NSObject {

    @objc class ValidationError: NSObject {
        @objc let header: String
        @objc let body: String
        @objc let continueTitle: String
        @objc let cancelTitle: String

        @objc let continueURL: URL?

        init(header: String, body: String, continueTitle: String, cancelTitle: String, continueURL: URL? = nil) {
            self.header = header
            self.body = body
            self.continueTitle = continueTitle
            self.cancelTitle = cancelTitle
            self.continueURL = continueURL
        }
    }

    /// Validate which account type has an error and return the information for an alert
    ///
    /// - Parameters:
    ///     - connections: An array of `KeyringConnection` instances to normalize.
    ///     - publicizeService: The publicize service for the fetched keyring connections.
    ///
    /// - Returns: An instance of `ValidationError` object, this is a plain object just with the information for an alert.
    ///
    @objc func validateConnections(_  connections: [KeyringConnection], with publicizeService: PublicizeService) -> ValidationError? {
        let accounts = accountsFromKeyringConnections(connections, with: publicizeService)

        if publicizeService.serviceID == PublicizeService.facebookServiceID, accounts.isEmpty {
            return facebookPublicizeAlertFields()
        }

        return nil
    }

    /// Normalizes available accounts for a KeyringConnection and its `additionalExternalUsers`
    ///
    /// - Parameter connections: An array of `KeyringConnection` instances to normalize.
    ///
    /// - Returns: An array of `KeyringAccount` objects.
    ///
    func accountsFromKeyringConnections(_ connections: [KeyringConnection], with publicizeService: PublicizeService) -> [KeyringAccount] {
        var accounts = [KeyringAccount]()

        for connection in connections {
            let acct = KeyringAccount(name: connection.externalDisplay, externalID: nil, externalIDForConnection: connection.externalID, keyringConnection: connection)

            // Do not include the service if it only supports external users.
            if !publicizeService.externalUsersOnly {
                accounts.append(acct)
            }

            for externalUser in connection.additionalExternalUsers {
                let acct = KeyringAccount(name: externalUser.externalName, externalID: externalUser.externalID, externalIDForConnection: externalUser.externalID, keyringConnection: connection)
                accounts.append(acct)
            }
        }

        return accounts
    }

}

// MARK: - Alert Message Types

private extension KeyringAccountHelper {

    func facebookPublicizeAlertFields() -> ValidationError {
        let alertHeaderMessage = NSLocalizedString("Not Connected",
                                                   comment: "Error title for alert, shown to a user who is trying to share to Facebook but does not have any available Facebook Pages.")
        let alertBodyMessage = NSLocalizedString("The Facebook connection cannot find any Pages. Publicize cannot connect to Facebook Profiles, only published Pages.",
                                                 comment: "Error message shown to a user who is trying to share to Facebook but does not have any available Facebook Pages.")
        let continueActionTitle = NSLocalizedString("Learn more", comment: "A button title.")
        let cancelActionTitle = NSLocalizedString("OK", comment: "A button title for closing the dialog.")

        return ValidationError(header: alertHeaderMessage,
                               body: alertBodyMessage,
                               continueTitle: continueActionTitle,
                               cancelTitle: cancelActionTitle,
                               continueURL: URL(string: "https://en.support.wordpress.com/publicize/#facebook-pages"))
    }

}
