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

@objc class ConfirmationAlertFields: NSObject {
    @objc let header: String
    @objc let body: String
    @objc let continueTitle: String
    @objc let cancelTitle: String

    init(header: String, body: String, continueTitle: String, cancelTitle: String) {
        self.header = header
        self.body = body
        self.continueTitle = continueTitle
        self.cancelTitle = cancelTitle
    }
}

@objc class KeyringAccountHelper: NSObject {

    @objc func showNoticeFromConnections(_  connections: [KeyringConnection], with publicize: PublicizeService) -> Bool {
        guard publicize.serviceID == PublicizeService.facebookServiceID else {
            return false
        }

        let accounts = accountsFromKeyringConnections(connections, with: publicize)
        return accounts.isEmpty
    }

    /// Validate which account type has error and return the information for an alert
    ///
    /// - Parameter publicize: The publicize service for the fetched keyring connections.
    ///
    /// - Returns: An instance of `ConfirmationAlertFields` object, this is a plain object just with the information for an alert.
    ///
    @objc func createErrorAlertFields(for publicize: PublicizeService) -> ConfirmationAlertFields? {
        if publicize.serviceID == PublicizeService.facebookServiceID {
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
    func accountsFromKeyringConnections(_ connections: [KeyringConnection], with publicize: PublicizeService) -> [KeyringAccount] {
        var accounts = [KeyringAccount]()

        for connection in connections {
            let acct = KeyringAccount(name: connection.externalDisplay, externalID: nil, externalIDForConnection: connection.externalID, keyringConnection: connection)

            // Do not include the service if it only supports external users.
            if !publicize.externalUsersOnly {
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

    func facebookPublicizeAlertFields() -> ConfirmationAlertFields {
        let alertHeaderMessage = NSLocalizedString("No Pages Found",
                                                   comment: "Error title for alert, shown to a user who is trying to share to Facebook but does not have any available Facebook Pages.")
        let alertBodyMessage = NSLocalizedString("The Facebook connection could not be made because this account does not have access to any pages. Facebook supports sharing connections to Facebook Pages, but not to Facebook Profiles.",
                                                 comment: "Error message shown to a user who is trying to share to Facebook but does not have any available Facebook Pages.")
        let continueActionTitle = NSLocalizedString("Learn more", comment: "A button title.")
        let cancelActionTitle = NSLocalizedString("OK", comment: "Cancel action title")

        return ConfirmationAlertFields(header: alertHeaderMessage,
                                       body: alertBodyMessage,
                                       continueTitle: continueActionTitle,
                                       cancelTitle: cancelActionTitle)
    }

}
