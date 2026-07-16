import Foundation
import SVProgressHUD
import WordPressData

/// Seals this device's WordPress.com session and sends it to a discovered receiver, surfacing
/// progress with a HUD. Shared by the manual Send Session browser and the always-on foreground
/// monitor, so both paths behave identically.
enum DebugSessionTransferSendService {
    @MainActor
    static func send(to receiver: DebugSessionTransferBrowser.DiscoveredReceiver) async {
        guard let token = AccountHelper.authToken else {
            SVProgressHUD.showError(withStatus: Strings.notSignedIn)
            return
        }
        let username = (try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext))?
            .username

        SVProgressHUD.show(withStatus: Strings.sending)
        do {
            let session = DebugWordPressComSession(token: token, username: username)
            let envelope = try DebugSessionTransferCrypto.seal(session, to: receiver.info.publicKey)
            try await DebugSessionTransferSender.send(envelope, to: receiver.endpoint)
            SVProgressHUD.showSuccess(withStatus: Strings.sent)
        } catch {
            SVProgressHUD.showError(withStatus: error.localizedDescription)
        }
    }
}

private enum Strings {
    static let sending = NSLocalizedString(
        "debugMenu.sessionTransfer.send.sending",
        value: "Sending…",
        comment: "Status shown while sending a session"
    )
    static let sent = NSLocalizedString(
        "debugMenu.sessionTransfer.send.sent",
        value: "Session sent",
        comment: "Status shown after a session was sent successfully"
    )
    static let notSignedIn = NSLocalizedString(
        "debugMenu.sessionTransfer.send.notSignedIn",
        value: "Not signed in to WordPress.com",
        comment: "Shown when there is no WordPress.com session on this device to send"
    )
}
