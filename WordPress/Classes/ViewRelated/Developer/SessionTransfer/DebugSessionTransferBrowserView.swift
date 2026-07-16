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
        .sheet(item: $pendingConsent) { receiver in
            ConsentSheet(receiver: receiver) {
                pendingConsent = nil
                Task { await send(to: receiver) }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
        }
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

/// Confirmation shown before a session leaves this device, styled after the system "Share Wi-Fi
/// Password" sheet. It names the destination device and shows the receiver's key fingerprint so it
/// can be compared against the one on the receiver's screen before sending — a manual check that the
/// session is being sealed to the intended device and not an impostor advertising the same name.
private struct ConsentSheet: View {
    let receiver: DebugSessionTransferBrowser.DiscoveredReceiver
    let onSend: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var fingerprint: String {
        DebugSessionTransferCrypto.fingerprint(of: receiver.info.publicKey)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(SharedStrings.Button.close)
            }

            Text(Strings.sheetTitle)
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)

            Text(String(format: Strings.sheetBody, receiver.info.name))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Spacer(minLength: 20)

            Image(systemName: "person.badge.key.fill")
                .font(.system(size: 52))
                .foregroundStyle(.blue)

            VStack(spacing: 2) {
                Text(Strings.verification)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(fingerprint)
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                    .textSelection(.enabled)
            }
            .padding(.top, 20)

            Spacer(minLength: 20)

            Button(action: onSend) {
                Text(Strings.send)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.blue)
        }
        .padding(24)
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
    static let sheetTitle = NSLocalizedString(
        "debugMenu.sessionTransfer.send.sheetTitle",
        value: "WordPress.com Session",
        comment: "Title of the sheet shown before sending a WordPress.com session to another device"
    )
    static let sheetBody = NSLocalizedString(
        "debugMenu.sessionTransfer.send.sheetBody",
        value: "Do you want to log “%@” in to your WordPress.com account?",
        comment: "Body of the send confirmation sheet; %@ is the destination device's name"
    )
    static let verification = NSLocalizedString(
        "debugMenu.sessionTransfer.send.verification",
        value: "Verification",
        comment: "Label above the key fingerprint the user compares against the receiver's screen"
    )
    static let send = NSLocalizedString(
        "debugMenu.sessionTransfer.send.confirm",
        value: "Send Session",
        comment: "Button that confirms sending the session to log the other device in"
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
