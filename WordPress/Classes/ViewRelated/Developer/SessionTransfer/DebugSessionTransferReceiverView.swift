import BuildSettingsKit
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

/// Debug-only screen that listens for a WordPress.com session pushed from another device on the
/// same Wi-Fi and signs the app in with it. Most useful in the Simulator, where the listener is
/// reachable from a physical device via the host Mac's LAN address.
struct DebugSessionTransferReceiverView: View {
    @StateObject private var receiver = DebugSessionTransferReceiver()

    var body: some View {
        List {
            switch receiver.state {
            case .starting:
                progressRow(Strings.starting)
            case .listening(let address, let port):
                listeningSection(address: address, port: port)
            case .signingIn:
                progressRow(Strings.signingIn)
            case .signedIn(let username):
                Section {
                    Label(
                        username.map { String(format: Strings.signedInAs, $0) } ?? Strings.signedIn,
                        systemImage: "checkmark.circle.fill"
                    )
                    .foregroundStyle(.green)
                }
            case .failed(let message):
                Section {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { receiver.start() }
        .onDisappear { receiver.stop() }
    }

    private func progressRow(_ title: String) -> some View {
        Section {
            HStack(spacing: 12) {
                ProgressView()
                Text(title)
            }
        }
    }

    @ViewBuilder
    private func listeningSection(address: String?, port: UInt16) -> some View {
        if let address {
            Section {
                LabeledContent(Strings.address) {
                    Text(verbatim: "\(address):\(port)")
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
                LabeledContent(Strings.verification) {
                    Text(receiver.fingerprint)
                        .font(.system(.title3, design: .monospaced).weight(.semibold))
                        .textSelection(.enabled)
                }
            } header: {
                Text(Strings.waiting)
            } footer: {
                Text(Strings.instructions)
            }

            if let qr = qrImage(for: sendSessionURL(address: address, port: port)) {
                Section {
                    HStack {
                        Spacer()
                        Image(uiImage: qr)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                        Spacer()
                    }
                } header: {
                    Text(Strings.scanHeader)
                }
            }
        } else {
            Section {
                Label(Strings.noAddress, systemImage: "wifi.slash")
                    .foregroundStyle(.secondary)
            } header: {
                Text(Strings.waiting)
            }
        }
    }

    /// The `send-session` deep link the receiver's QR encodes. Scanning it on the signed-in device
    /// opens the app (via the app's URL scheme) to a confirmation prompt that seals the session to
    /// this receiver's public key (`pk`) before sending it.
    private func sendSessionURL(address: String, port: UInt16) -> String {
        "\(BuildSettings.current.appURLScheme)://send-session?host=\(address)&port=\(port)&pk=\(receiver.publicKeyToken)"
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
        "debugMenu.sessionTransfer.receive.title",
        value: "Receive Session",
        comment: "Title for the debug screen that receives a WordPress.com session from another device"
    )
    static let starting = NSLocalizedString(
        "debugMenu.sessionTransfer.receive.starting",
        value: "Starting…",
        comment: "Status shown while the session receiver is starting up"
    )
    static let waiting = NSLocalizedString(
        "debugMenu.sessionTransfer.receive.waiting",
        value: "Waiting for a session",
        comment: "Header shown while the session receiver waits for an incoming session"
    )
    static let address = NSLocalizedString(
        "debugMenu.sessionTransfer.receive.address",
        value: "Address",
        comment: "Label for the network address the receiver is listening on"
    )
    static let verification = NSLocalizedString(
        "debugMenu.sessionTransfer.receive.verification",
        value: "Verification",
        comment: "Label for the short key fingerprint a sender can compare to confirm the pairing"
    )
    static let noAddress = NSLocalizedString(
        "debugMenu.sessionTransfer.receive.noAddress",
        value: "No Wi-Fi address found",
        comment: "Shown when no local network address is available to listen on"
    )
    static let instructions = NSLocalizedString(
        "debugMenu.sessionTransfer.receive.instructions",
        value:
            "Send your WordPress.com session here from a signed-in device on the same Wi-Fi.",
        comment: "Instructions explaining how to push a session to this device"
    )
    static let scanHeader = NSLocalizedString(
        "debugMenu.sessionTransfer.receive.scanHeader",
        value: "Scan to connect",
        comment: "Header above a QR code the other device scans to reach this device"
    )
    static let signingIn = NSLocalizedString(
        "debugMenu.sessionTransfer.receive.signingIn",
        value: "Signing in…",
        comment: "Status shown while signing in with a received session"
    )
    static let signedIn = NSLocalizedString(
        "debugMenu.sessionTransfer.receive.signedIn",
        value: "Signed in",
        comment: "Status shown after signing in with a received session"
    )
    static let signedInAs = NSLocalizedString(
        "debugMenu.sessionTransfer.receive.signedInAs",
        value: "Signed in as %@",
        comment: "Status shown after signing in; %@ is the account username"
    )
}
