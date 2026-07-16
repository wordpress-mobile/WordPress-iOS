import SVProgressHUD
import SwiftUI
import WordPressData

/// Debug-only screen that browses for session-transfer receivers on the local network and, after an
/// explicit confirmation, logs the selected device into this device's WordPress.com account.
struct DebugSessionTransferBrowserView: View {
    @StateObject private var browser = DebugSessionTransferBrowser()
    @State private var pendingConsent: DebugSessionTransferBrowser.DiscoveredReceiver?

    var body: some View {
        List {
            if browser.receivers.isEmpty {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text(Strings.searching)
                    }
                }
            } else {
                Section {
                    ForEach(browser.receivers) { receiver in
                        Button {
                            pendingConsent = receiver
                        } label: {
                            row(for: receiver)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(Strings.nearbyDevices)
                } footer: {
                    Text(Strings.footer)
                }
            }
        }
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { browser.start() }
        .onDisappear { browser.stop() }
        .alert(Strings.consentTitle, isPresented: consentPresented, presenting: pendingConsent) { receiver in
            Button(Strings.allow) {
                Task { await send(to: receiver) }
            }
            Button(SharedStrings.Button.cancel, role: .cancel) {}
        } message: { receiver in
            Text(String(format: Strings.consentMessage, receiver.info.name))
        }
    }

    private var consentPresented: Binding<Bool> {
        Binding(get: { pendingConsent != nil }, set: { if !$0 { pendingConsent = nil } })
    }

    private func row(for receiver: DebugSessionTransferBrowser.DiscoveredReceiver) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "iphone")
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text(receiver.info.name)
                Text(subtitle(for: receiver.info))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func subtitle(for info: DebugSessionReceiverInfo) -> String {
        var parts = [info.model]
        if info.isSimulator {
            parts.append(Strings.simulator)
        }
        if info.isSignedIn {
            parts.append(Strings.signedIn)
        }
        return parts.joined(separator: " · ")
    }

    @MainActor
    private func send(to receiver: DebugSessionTransferBrowser.DiscoveredReceiver) async {
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
    static let title = NSLocalizedString(
        "debugMenu.sessionTransfer.send.title",
        value: "Send Session",
        comment: "Title for the debug screen that logs a nearby device into this account"
    )
    static let searching = NSLocalizedString(
        "debugMenu.sessionTransfer.send.searching",
        value: "Searching for devices…",
        comment: "Shown while browsing the local network for receivers"
    )
    static let nearbyDevices = NSLocalizedString(
        "debugMenu.sessionTransfer.send.nearbyDevices",
        value: "Nearby devices",
        comment: "Section header listing discovered receivers"
    )
    static let footer = NSLocalizedString(
        "debugMenu.sessionTransfer.send.footer",
        value: "Devices with Receive Session open on the same Wi-Fi appear here.",
        comment: "Explanation below the list of discovered receivers"
    )
    static let simulator = NSLocalizedString(
        "debugMenu.sessionTransfer.send.simulator",
        value: "Simulator",
        comment: "Badge shown for a receiver running in the iOS Simulator"
    )
    static let signedIn = NSLocalizedString(
        "debugMenu.sessionTransfer.send.alreadySignedIn",
        value: "Signed in",
        comment: "Badge shown when a receiver already has an account (sending will replace it)"
    )
    static let consentTitle = NSLocalizedString(
        "debugMenu.sessionTransfer.send.consentTitle",
        value: "Allow Login?",
        comment: "Title of the confirmation before logging another device into this account"
    )
    static let consentMessage = NSLocalizedString(
        "debugMenu.sessionTransfer.send.consentBody",
        value: "Device “%@” is asking to log in to your WordPress.com account.",
        comment: "Confirmation body; %@ is the requesting device's name"
    )
    static let allow = NSLocalizedString(
        "debugMenu.sessionTransfer.send.allow",
        value: "Allow",
        comment: "Button that confirms logging the other device into this account"
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
