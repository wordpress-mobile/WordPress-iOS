import CoreImage.CIFilterBuiltins
import SwiftUI
import WordPressShared

/// Shown on the receiver, over the login screen, when a nearby device signals it wants to sign this
/// device in: it renders the receiver's freshly minted public key as a QR for the sender to scan.
///
/// This QR is the *only* place the receiver's key is ever exposed — it never goes on the network. The
/// sender seals the session to the key it reads here, which is what makes the exchange safe against an
/// impostor on the same Wi-Fi. See the security note on `DebugSessionTransferReceiver`.
struct DebugSessionTransferChallengeView: View {
    let publicKey: Data
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onCancel) {
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

            Text(Strings.subtitle)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Spacer(minLength: 24)

            if let qr = qrImage(for: DebugSessionTransferCrypto.encodePublicKey(publicKey)) {
                Image(uiImage: qr)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 240)
                    .accessibilityHidden(true)
            }

            Spacer(minLength: 24)

            HStack(spacing: 8) {
                ProgressView()
                Text(Strings.waiting)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
    }

    /// A QR code encoding `string`, for the other device's camera to scan.
    private func qrImage(for string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "debugMenu.sessionTransfer.challenge.title",
        value: "Scan to sign in",
        comment: "Title of the QR screen a signed-out device shows so a nearby device can sign it in"
    )
    static let subtitle = NSLocalizedString(
        "debugMenu.sessionTransfer.challenge.subtitle",
        value: "Point the other device's camera at this code to finish signing in.",
        comment: "Instruction under the QR the receiver shows"
    )
    static let waiting = NSLocalizedString(
        "debugMenu.sessionTransfer.challenge.waiting",
        value: "Waiting for the other device…",
        comment: "Status shown under the QR while waiting for the sender to scan and send"
    )
}
