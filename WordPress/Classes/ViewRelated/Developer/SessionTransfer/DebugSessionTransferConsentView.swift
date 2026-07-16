import SwiftUI
import WordPressShared

/// Confirmation shown before a WordPress.com session leaves this device — reached either by tapping a
/// receiver in the Send Session browser or by the always-on monitor surfacing a nearby device that is
/// asking for help. Styled after the system "Share Wi-Fi Password" sheet, and shows the receiver's key
/// fingerprint so it can be compared against the "Verification" value on the receiver's screen before
/// sending.
struct DebugSessionTransferConsentView: View {
    let receiver: DebugSessionTransferBrowser.DiscoveredReceiver
    let onSend: () -> Void
    let onClose: () -> Void

    private var fingerprint: String {
        DebugSessionTransferCrypto.fingerprint(of: receiver.info.publicKey)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(SharedStrings.Button.close)
            }

            Text(Strings.title)
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)

            Text(String(format: Strings.body, receiver.info.name))
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
        "debugMenu.sessionTransfer.send.sheetTitle",
        value: "WordPress.com Session",
        comment: "Title of the sheet shown before sending a WordPress.com session to another device"
    )
    static let body = NSLocalizedString(
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
}
