import CryptoKit
import Foundation
import Logging
import Network
import UIDeviceIdentifier
import UIKit
import WordPressData

/// Receives a WordPress.com session (OAuth bearer token) pushed from another device over the local
/// network, so an app instance — most usefully one running in the iOS Simulator — can be signed in
/// without repeating the web OAuth flow.
///
/// The receiver binds a TCP listener. In the Simulator that socket lives on the host Mac, so it is
/// reachable from a physical device on the same Wi-Fi via the Mac's LAN address, and it advertises
/// itself over Bonjour. It publishes a per-session X25519 public key in the Bonjour TXT record; the
/// sender seals the session to that key, so the bearer token is never readable in flight even though
/// the transport is plaintext TCP.
///
/// It runs headless, started and stopped by `DebugSessionTransferReceiverService` while the app is on
/// the login screen. The wire protocol is a single length-prefixed message each way (see
/// `DebugSessionTransferFraming`): the sender sends the sealed `DebugSessionEnvelope`, the receiver
/// replies with a small JSON status.
final class DebugSessionTransferReceiver {
    /// Bonjour service type the receiver advertises so a sender can discover it on the local network.
    /// Must be listed in `NSBonjourServices` in the app's Info.plist.
    static let bonjourServiceType = "_wpcom-login._tcp"

    /// Version of the transfer protocol, advertised so a sender can reject incompatible receivers.
    static let protocolVersion = "1"

    /// Per-session key agreement pair. A sender seals the session to `publicKey`; only this instance
    /// holds the private half, so nobody else — including a network sniffer — can read the token.
    private let privateKey = Curve25519.KeyAgreement.PrivateKey()

    private var publicKey: Data { privateKey.publicKey.rawRepresentation }

    private let signIn: (String) async throws -> String?
    private let queue = DispatchQueue(label: "org.wordpress.debug-session-transfer.receiver")
    private var listener: NWListener?

    init(signIn: @escaping (String) async throws -> String? = DebugSessionTransferReceiver.defaultSignIn) {
        self.signIn = signIn
    }

    // MARK: - Advertised identity

    /// Human-readable name for this device, shown in a sender's Bonjour discovery list.
    static var deviceName: String {
        UIDevice.current.name
    }

    /// Marketing model name (e.g. "iPhone 15 Pro"). On the Simulator this resolves the *simulated*
    /// model via `SIMULATOR_MODEL_IDENTIFIER` rather than reporting the Mac's architecture.
    static var deviceModel: String {
        let identifier =
            ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? UIDeviceHardware.platform()
        return UIDeviceHardware.platformString(forType: identifier)
    }

    private static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// Metadata advertised alongside the service (see `DebugSessionReceiverInfo`): protocol version,
    /// device identity, which app, whether it's already signed in (so a sender can warn before
    /// replacing an account), and the public key to seal the session to.
    private func advertisedInfo() -> DebugSessionReceiverInfo {
        DebugSessionReceiverInfo(
            protocolVersion: Self.protocolVersion,
            name: Self.deviceName,
            model: Self.deviceModel,
            isSimulator: Self.isSimulator,
            app: AppConfiguration.isJetpack ? "jetpack" : "wordpress",
            isSignedIn: AccountHelper.isDotcomAvailable(),
            publicKey: publicKey
        )
    }

    func start() {
        do {
            let listener = try NWListener(using: .tcp)
            self.listener = listener
            // Advertise over Bonjour so a sender can discover this receiver. In the Simulator the
            // listener is a host socket, so this registers with the Mac's mDNSResponder and is
            // advertised on the real LAN.
            listener.service = NWListener.Service(
                name: Self.deviceName,
                type: Self.bonjourServiceType,
                txtRecord: NWTXTRecord(advertisedInfo().txtDictionary)
            )
            listener.stateUpdateHandler = { [weak self] state in
                self?.listenerStateChanged(state)
            }
            listener.newConnectionHandler = { [weak self] connection in
                self?.accept(connection)
            }
            listener.start(queue: queue)
        } catch {
            Loggers.networking.error("Session transfer listener failed to start: \(error)")
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    // MARK: - Listener

    private func listenerStateChanged(_ state: NWListener.State) {
        switch state {
        case .ready:
            let port = listener?.port?.rawValue ?? 0
            let address = Self.primaryLANAddress() ?? "?"
            Loggers.networking.info("Session transfer receiver listening on \(address):\(port)")
        case .failed(let error):
            Loggers.networking.error("Session transfer listener failed: \(error)")
        default:
            break
        }
    }

    private func accept(_ connection: NWConnection) {
        connection.start(queue: queue)
        DebugSessionTransferFraming.readMessage(from: connection) { [weak self] result in
            switch result {
            case .success(let message):
                self?.handle(message: message, on: connection)
            case .failure:
                connection.cancel()
            }
        }
    }

    private func handle(message: Data, on connection: NWConnection) {
        guard let envelope = try? JSONDecoder().decode(DebugSessionEnvelope.self, from: message),
            let session = try? DebugSessionTransferCrypto.open(envelope, with: privateKey)
        else {
            respond(["error": "invalid_payload"], on: connection)
            return
        }

        // Acknowledge delivery immediately, then sign in independently. Signing in fetches account
        // details and syncs blogs, which can take longer than the sender's timeout — and delivery is
        // all the sender is waiting on.
        respond(["status": "signed_in"], on: connection)
        stop()

        Task {
            do {
                _ = try await self.signIn(session.token)
                // Swap the window root from the login prologue to the signed-in app. Creating the
                // account isn't enough on its own — without this the app stays on the login screen.
                // Mirrors what `WordPressAuthenticationManager` does after the normal OAuth flow;
                // `showUI()` shows the app now that `AccountHelper.isLoggedIn` is true.
                DispatchQueue.main.async {
                    WordPressAppDelegate.shared?.windowManager.showUI()
                }
            } catch {
                Loggers.networking.error("Session transfer sign-in failed: \(error)")
            }
        }
    }

    private func respond(_ status: [String: String], on connection: NWConnection) {
        let body = (try? JSONSerialization.data(withJSONObject: status)) ?? Data()
        // `isComplete: true` flushes the reply and half-closes the connection (FIN). Sending and
        // then immediately cancelling truncates the reply on a real network — the bytes are dropped
        // before they reach the sender, which then waits forever for them. (Localhost flushes fast
        // enough to hide this, which is why the Mac probe worked but a device over Wi-Fi didn't.)
        connection.send(
            content: DebugSessionTransferFraming.encode(body),
            isComplete: true,
            completion: .contentProcessed { _ in }
        )
    }

    // MARK: - Sign in

    /// Signs the app in with the received bearer token and returns the account username.
    ///
    /// Mirrors the tail of `WordPressDotComAuthenticator.attemptSignIn`: create/update the account
    /// from the token (which fetches account details + blogs from the API), then post
    /// `WPSigninDidFinishNotification` so the app navigates into its signed-in state.
    static func defaultSignIn(token: String) async throws -> String? {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                WordPressComSyncService()
                    .syncWPCom(
                        authToken: token,
                        isJetpackLogin: false,
                        onSuccess: { account in
                            let username = account.username
                            let name = Foundation.Notification.Name(
                                rawValue: WordPressAuthenticationManager.WPSigninDidFinishNotification
                            )
                            NotificationCenter.default.post(name: name, object: account)
                            continuation.resume(returning: username)
                        },
                        onFailure: { error in
                            continuation.resume(throwing: error)
                        }
                    )
            }
        }
    }

    // MARK: - LAN address

    /// The host's primary IPv4 address on the local network, preferring Wi-Fi (`en0`).
    ///
    /// Run inside the Simulator this returns the Mac's address (the sim shares the host's
    /// interfaces), which is exactly what a physical device must connect to.
    static func primaryLANAddress() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        var candidates: [(name: String, ip: String)] = []
        for pointer in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let flags = Int32(pointer.pointee.ifa_flags)
            guard (flags & IFF_UP) == IFF_UP, (flags & IFF_LOOPBACK) == 0 else { continue }
            guard let addr = pointer.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET) else { continue }

            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = getnameinfo(
                addr,
                socklen_t(addr.pointee.sa_len),
                &host,
                socklen_t(host.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            guard result == 0 else { continue }
            candidates.append((String(cString: pointer.pointee.ifa_name), String(cString: host)))
        }

        return candidates.first(where: { $0.name == "en0" })?.ip
            ?? candidates.first(where: { $0.name.hasPrefix("en") })?.ip
            ?? candidates.first?.ip
    }
}
