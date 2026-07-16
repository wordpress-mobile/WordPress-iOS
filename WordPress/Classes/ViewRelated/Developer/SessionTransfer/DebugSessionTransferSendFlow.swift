import Foundation
import Network
import SVProgressHUD
import UIKit
import WordPressData
import WordPressUI

/// Runs the sender side of a session transfer: connect to the chosen receiver, signal intent, let the
/// user scan the receiver's QR, then seal this device's WordPress.com session to the scanned key and
/// send it.
///
/// The key sealed to comes only from the scan, never from the network — that's what makes the transfer
/// safe against an impostor on the same Wi-Fi. See the security note on `DebugSessionTransferReceiver`.
///
/// The whole exchange runs on the main queue (the messages are tiny and the flow is driven by UI), so
/// there's no cross-thread state to guard.
final class DebugSessionTransferSendFlow {
    private let receiver: DebugSessionTransferBrowser.DiscoveredReceiver
    private let session: DebugWordPressComSession

    private var connection: NWConnection?
    private weak var scanner: UIViewController?
    private var finished = false

    /// One in-flight flow at a time; the static reference also keeps it alive while it runs, since
    /// nothing else owns it.
    private static var active: DebugSessionTransferSendFlow?

    private init(receiver: DebugSessionTransferBrowser.DiscoveredReceiver, session: DebugWordPressComSession) {
        self.receiver = receiver
        self.session = session
    }

    /// Starts a transfer to `receiver`. Requires a WordPress.com session on this device to send.
    static func start(to receiver: DebugSessionTransferBrowser.DiscoveredReceiver) {
        guard let token = AccountHelper.authToken else {
            SVProgressHUD.showError(withStatus: Strings.notSignedIn)
            return
        }
        let username = (try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext))?
            .username
        let flow = DebugSessionTransferSendFlow(
            receiver: receiver,
            session: DebugWordPressComSession(token: token, username: username)
        )
        active = flow
        flow.connect()
    }

    private func connect() {
        let connection = NWConnection(to: receiver.endpoint, using: .tcp)
        self.connection = connection
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.sendIntent()
            case .failed(let error):
                self?.finish(.transport(error.localizedDescription))
            default:
                break
            }
        }
        // Backstop covering the whole exchange, including the human scan.
        DispatchQueue.main.asyncAfter(deadline: .now() + 120) { [weak self] in
            self?.finish(.timedOut)
        }
        connection.start(queue: .main)
    }

    private func sendIntent() {
        guard let connection, !finished else { return }
        let intent = DebugSessionTransferIntent(protocolVersion: DebugSessionTransferReceiver.protocolVersion)
        guard let data = try? JSONEncoder().encode(intent) else {
            finish(.transport("Could not encode intent."))
            return
        }
        connection.send(
            content: DebugSessionTransferFraming.encode(data),
            completion: .contentProcessed { [weak self] error in
                if let error {
                    self?.finish(.transport(error.localizedDescription))
                } else {
                    self?.presentScanner()
                }
            }
        )
    }

    private func presentScanner() {
        guard !finished else { return }
        guard let presenter = WordPressAppDelegate.shared?.window?.topmostPresentedViewController else {
            finish(.cancelled)
            return
        }
        let scanner = DebugSessionTransferScannerViewController(
            deviceName: receiver.info.name,
            onScan: { [weak self] publicKey in self?.sendEnvelope(sealedTo: publicKey) },
            onCancel: { [weak self] in self?.finish(.cancelled) }
        )
        self.scanner = scanner
        presenter.present(scanner, animated: true)
    }

    private func sendEnvelope(sealedTo publicKey: Data) {
        guard let connection, !finished else { return }
        scanner?.dismiss(animated: true)
        SVProgressHUD.show(withStatus: Strings.sending)
        do {
            let envelope = try DebugSessionTransferCrypto.seal(session, to: publicKey)
            let data = try JSONEncoder().encode(envelope)
            connection.send(
                content: DebugSessionTransferFraming.encode(data),
                isComplete: true,
                completion: .contentProcessed { [weak self] error in
                    if let error {
                        self?.finish(.transport(error.localizedDescription))
                    } else {
                        self?.readAck()
                    }
                }
            )
        } catch {
            finish(.transport(error.localizedDescription))
        }
    }

    private func readAck() {
        guard let connection else { return }
        DebugSessionTransferFraming.readMessage(from: connection) { [weak self] result in
            switch result {
            case .success(let data):
                let response = try? JSONDecoder().decode([String: String].self, from: data)
                if let error = response?["error"] {
                    self?.finish(.rejected(error))
                } else if response?["status"] == "signed_in" {
                    self?.finish(nil)
                } else {
                    self?.finish(.invalidResponse)
                }
            case .failure(let error):
                self?.finish(.transport(error.localizedDescription))
            }
        }
    }

    /// Terminal handler. `error == nil` is success. Idempotent — only the first call takes effect.
    private func finish(_ error: SendError?) {
        guard !finished else { return }
        finished = true
        connection?.cancel()
        connection = nil
        scanner?.dismiss(animated: true)

        switch error {
        case nil:
            SVProgressHUD.showSuccess(withStatus: Strings.sent)
        case .cancelled:
            SVProgressHUD.dismiss()
        case .some(let error):
            SVProgressHUD.showError(withStatus: error.errorDescription ?? Strings.genericError)
        }
        Self.active = nil
    }

    private enum SendError: Error {
        case cancelled
        case timedOut
        case invalidResponse
        case rejected(String)
        case transport(String)

        var errorDescription: String? {
            switch self {
            case .cancelled:
                return nil
            case .timedOut:
                return Strings.timedOut
            case .invalidResponse:
                return Strings.invalidResponse
            case .rejected(let reason), .transport(let reason):
                return reason
            }
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
    static let timedOut = NSLocalizedString(
        "debugMenu.sessionTransfer.send.error.timedOut",
        value: "Timed out reaching the other device.",
        comment: "Error shown when the receiver could not be reached in time"
    )
    static let invalidResponse = NSLocalizedString(
        "debugMenu.sessionTransfer.send.error.invalidResponse",
        value: "Unexpected response from the other device.",
        comment: "Error shown when the receiver's response could not be understood"
    )
    static let genericError = NSLocalizedString(
        "debugMenu.sessionTransfer.send.error.generic",
        value: "Could not send the session.",
        comment: "Generic error shown when sending a session failed"
    )
}
