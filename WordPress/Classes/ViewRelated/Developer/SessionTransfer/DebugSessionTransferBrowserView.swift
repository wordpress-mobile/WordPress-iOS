import SwiftUI

/// Debug-only screen that browses for session-transfer receivers on the local network. Tapping one
/// starts the send flow: it signals intent, opens the camera to scan that device's QR, then seals and
/// sends this device's WordPress.com session to the scanned key.
struct DebugSessionTransferBrowserView: View {
    @StateObject private var browser = DebugSessionTransferBrowser()

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
                            DebugSessionTransferSendFlow.start(to: receiver)
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
        value:
            "Devices sitting on the login screen on the same Wi-Fi appear here. Tap one to scan its code and sign it in.",
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
}
