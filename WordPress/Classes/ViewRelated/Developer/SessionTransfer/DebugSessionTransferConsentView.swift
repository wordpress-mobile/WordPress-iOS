import SwiftUI
import WordPressShared

/// Offer shown by the always-on monitor when a nearby device is asking to be signed in: it names the
/// device and, on confirm, kicks off the send flow (which opens the scanner to read that device's QR).
/// Styled after the system "Share Wi-Fi Password" sheet.
///
/// There's no fingerprint to compare here — verification happens by scanning the QR on the other
/// device's screen, not by eyeballing a code. See the security note on `DebugSessionTransferReceiver`.
struct DebugSessionTransferConsentView: View {
    let deviceName: String
    let onContinue: () -> Void
    let onClose: () -> Void

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

            Text(String(format: Strings.body, deviceName))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Spacer(minLength: 24)

            Image(systemName: "person.badge.key.fill")
                .font(.system(size: 52))
                .foregroundStyle(.blue)

            Spacer(minLength: 24)

            Button(action: onContinue) {
                Text(Strings.continueButton)
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
        value: "Log “%@” in to your WordPress.com account? You'll scan a code on its screen to confirm.",
        comment: "Body of the send confirmation sheet; %@ is the destination device's name"
    )
    static let continueButton = NSLocalizedString(
        "debugMenu.sessionTransfer.send.continue",
        value: "Continue",
        comment: "Button that proceeds to scan the other device's code and send the session"
    )
}
