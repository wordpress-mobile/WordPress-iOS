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

@objc class KeyringAccountController: NSObject {

    @objc func showFacebookNoticeFromConnections(_  connections: [KeyringConnection], with publicizeService: PublicizeService) -> Bool {
        guard publicizeService.serviceID == PublicizeService.facebookServiceID else {
            return false
        }

        let accountConnections = keyringAccountsFromKeyringConnections(connections, with: publicizeService)
        return accountConnections.isEmpty
    }


    /// Normalizes available accounts for a KeyringConnection and its `additionalExternalUsers`
    ///
    /// - Parameter connections: An array of `KeyringConnection` instances to normalize.
    ///
    /// - Returns: An array of `KeyringAccount` objects.
    ///
    func keyringAccountsFromKeyringConnections(_ connections: [KeyringConnection], with pulicize: PublicizeService) -> [KeyringAccount] {
        var accounts = [KeyringAccount]()

        for connection in connections {
            let acct = KeyringAccount(name: connection.externalDisplay, externalID: nil, externalIDForConnection: connection.externalID, keyringConnection: connection)

            // Do not include the service if it only supports external users.
            if !pulicize.externalUsersOnly {
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
