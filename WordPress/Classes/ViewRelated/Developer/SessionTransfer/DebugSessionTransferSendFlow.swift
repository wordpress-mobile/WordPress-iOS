import SVProgressHUD
import UIKit
import WordPressData

/// The QR-initiated flow for pushing this device's WordPress.com session to a receiver on the local
/// network. Triggered by a `send-session` deep link (produced by scanning the receiver's QR code).
///
/// The developer must explicitly confirm, so the token never leaves the device without a deliberate
/// tap — the developer initiates the transfer, it never happens silently. Debug/internal only.
@MainActor
enum DebugSessionTransferSendFlow {
    static func present(from presenter: UIViewController, host: String, port: UInt16, publicKey: Data) {
        guard let token = AccountHelper.authToken else {
            SVProgressHUD.showError(withStatus: Strings.notSignedIn)
            return
        }
        let username = (try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext))?
            .username
        let fingerprint = DebugSessionTransferCrypto.fingerprint(of: publicKey)

        let alert = UIAlertController(
            title: Strings.confirmTitle,
            message: String(format: Strings.confirmMessage, host, fingerprint),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: SharedStrings.Button.cancel, style: .cancel))
        alert.addAction(
            UIAlertAction(title: Strings.sendButton, style: .default) { _ in
                Task { await send(token: token, username: username, host: host, port: port, publicKey: publicKey) }
            }
        )
        presenter.present(alert, animated: true)
    }

    private static func send(token: String, username: String?, host: String, port: UInt16, publicKey: Data) async {
        SVProgressHUD.show(withStatus: Strings.sending)
        do {
            let session = DebugWordPressComSession(token: token, username: username)
            let envelope = try DebugSessionTransferCrypto.seal(session, to: publicKey)
            try await DebugSessionTransferSender.send(envelope, toHost: host, port: port)
            SVProgressHUD.showSuccess(withStatus: Strings.sent)
        } catch {
            SVProgressHUD.showError(withStatus: error.localizedDescription)
        }
    }

    private enum Strings {
        static let confirmTitle = NSLocalizedString(
            "debugMenu.sessionTransfer.send.confirmTitle",
            value: "Send WordPress.com Session?",
            comment: "Title of the confirmation shown before sending a sign-in session to another device"
        )
        static let confirmMessage = NSLocalizedString(
            "debugMenu.sessionTransfer.send.confirmMessage",
            value:
                "This sends your sign-in to %1$@ (verification %2$@), giving that device full access to your WordPress.com account.",
            comment:
                "Confirmation before sending a session; %1$@ is the destination address, %2$@ the verification code"
        )
        static let sendButton = NSLocalizedString(
            "debugMenu.sessionTransfer.send.sendButton",
            value: "Send",
            comment: "Button that confirms sending the session to the other device"
        )
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
}
