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
/// The receiver binds a TCP listener and advertises `_wpcom-login._tcp` over Bonjour (headless,
/// carrying no key). In the Simulator that socket lives on the host Mac, so it is reachable from a
/// physical device on the same Wi-Fi via the Mac's LAN address. It runs while the app is on the
/// login screen, driven by `DebugSessionTransferReceiverService`.
///
/// ## Security model
///
/// The handshake is designed so that the only way to hand this device a session is to physically
/// scan the QR it draws:
///
///   1. The sender signals `intent` (no key material).
///   2. On intent, the receiver mints a **fresh** X25519 key pair and shows the *public* half as a QR
///      **on its own screen** (`onChallenge`). The public key never travels the network — not over
///      Bonjour, not over this connection.
///   3. The sender scans that QR, seals the session to the scanned key, and sends the envelope.
///   4. The receiver opens it with the matching private key and signs in.
///
/// Because the public key exists only on the glass, a sender that never scanned it has nothing to
/// seal to and cannot produce anything this private key will open — that defeats both an impostor
/// *receiver* (a spoofed Bonjour advertisement, whose name is attacker-controllable) and an impostor
/// *sender* (a remote attacker trying to push a session). And because the key is fresh **per QR**,
/// successful decryption is itself proof the sender scanned *this* QR, and replay is impossible: an
/// envelope sealed to an earlier QR's key is undecryptable garbage to the current one. The AES-GCM
/// encryption (see `DebugSessionTransferCrypto`) separately keeps a passive sniffer from reading the
/// token. What this does *not* defend: someone who can physically see your screen and shoulder-surf
/// the QR — a person standing next to you.
final class DebugSessionTransferReceiver {
    /// Bonjour service type the receiver advertises so a sender can discover it on the local network.
    /// Must be listed in `NSBonjourServices` in the app's Info.plist.
    static let bonjourServiceType = "_wpcom-login._tcp"

    /// Version of the transfer protocol, advertised so a sender can reject an incompatible receiver.
    static let protocolVersion = "2"

    private let signIn: (String) async throws -> String?
    /// Called on the main thread with a freshly minted public key when a sender signals intent — the
    /// service renders it as a QR on screen. `onResolve` is called (main thread) when the exchange
    /// finishes, fails, or times out, so the service can take the QR back down.
    private let onChallenge: (Data) -> Void
    private let onResolve: () -> Void

    private let queue = DispatchQueue(label: "org.wordpress.debug-session-transfer.receiver")
    private var listener: NWListener?

    /// How long to keep a challenge (and its QR) alive waiting for the sealed envelope before giving
    /// up — long enough for the user to grant camera access and line up the scan.
    private static let challengeTimeout: TimeInterval = 120

    init(
        signIn: @escaping (String) async throws -> String? = DebugSessionTransferReceiver.defaultSignIn,
        onChallenge: @escaping (Data) -> Void = { _ in },
        onResolve: @escaping () -> Void = {}
    ) {
        self.signIn = signIn
        self.onChallenge = onChallenge
        self.onResolve = onResolve
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
    /// device identity, which app, and whether it's already signed in (so a sender can warn before
    /// replacing an account). Deliberately no key — that only ever appears in the QR.
    private func advertisedInfo() -> DebugSessionReceiverInfo {
        DebugSessionReceiverInfo(
            protocolVersion: Self.protocolVersion,
            name: Self.deviceName,
            model: Self.deviceModel,
            isSimulator: Self.isSimulator,
            app: AppConfiguration.isJetpack ? "jetpack" : "wordpress",
            isSignedIn: AccountHelper.isDotcomAvailable()
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
        // Message 1: the sender's intent. It carries no key — it only asks us to reveal our QR.
        DebugSessionTransferFraming.readMessage(from: connection) { [weak self] result in
            switch result {
            case .success(let data):
                self?.handleIntent(data, on: connection)
            case .failure:
                connection.cancel()
            }
        }
    }

    private func handleIntent(_ data: Data, on connection: NWConnection) {
        guard let intent = try? JSONDecoder().decode(DebugSessionTransferIntent.self, from: data),
            intent.protocolVersion == Self.protocolVersion
        else {
            respond(["error": "unsupported"], on: connection)
            return
        }

        // ── SECURITY (load-bearing) ─────────────────────────────────────────────────────────────
        // Mint a FRESH key pair for THIS transfer and hand only the public half to the on-screen QR.
        //
        //   * The public key never touches the network — not Bonjour, not this connection. It exists
        //     only on our screen, so a sender that didn't physically scan our QR has nothing to seal
        //     to and can't produce anything `privateKey` will open. Authenticity comes from the key
        //     being read off the glass, not asserted over the wire — which is what makes both an
        //     impostor receiver and an impostor sender useless.
        //   * A fresh key *per QR* makes successful decryption below proof that the sender scanned
        //     *this* QR, and makes replay impossible: an envelope sealed to a previous QR's key is
        //     undecryptable garbage to this one.
        //
        // Do NOT hoist this key to a stored property or reuse it across transfers — the guarantee
        // depends on it being minted fresh, here, every time.
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        let publicKey = privateKey.publicKey.rawRepresentation
        DispatchQueue.main.async { self.onChallenge(publicKey) }

        // Give up if the sealed envelope doesn't arrive — the sender abandoning the scan usually
        // closes the connection (surfacing as a read failure below), but this covers a silent drop.
        queue.asyncAfter(deadline: .now() + Self.challengeTimeout) { [weak connection] in
            connection?.cancel()
        }

        // Message 2: the sealed session, which the sender can only produce after scanning the QR.
        DebugSessionTransferFraming.readMessage(from: connection) { [weak self] result in
            switch result {
            case .success(let data):
                self?.handleEnvelope(data, on: connection, privateKey: privateKey)
            case .failure:
                self?.resolve()
                connection.cancel()
            }
        }
    }

    private func handleEnvelope(
        _ data: Data,
        on connection: NWConnection,
        privateKey: Curve25519.KeyAgreement.PrivateKey
    ) {
        guard let envelope = try? JSONDecoder().decode(DebugSessionEnvelope.self, from: data),
            let session = try? DebugSessionTransferCrypto.open(envelope, with: privateKey)
        else {
            // Undecryptable: sealed to a different key (so not a response to our QR) or corrupt.
            respond(["error": "invalid_payload"], on: connection)
            resolve()
            return
        }

        // Decryption succeeded ⇒ this envelope was sealed to the key we just drew ⇒ the sender scanned
        // our QR. Acknowledge delivery, take the QR down, stop listening, and sign in.
        respond(["status": "signed_in"], on: connection)
        resolve()
        stop()

        Task {
            do {
                _ = try await self.signIn(session.token)
                // Swap the window root from the login prologue to the signed-in app. Creating the
                // account isn't enough on its own — without this the app stays on the login screen.
                // Mirrors what `WordPressAuthenticationManager` does after the normal OAuth flow.
                DispatchQueue.main.async {
                    WordPressAppDelegate.shared?.windowManager.showUI()
                }
            } catch {
                Loggers.networking.error("Session transfer sign-in failed: \(error)")
            }
        }
    }

    /// Takes the challenge QR back down (idempotent — safe to call from any terminal path).
    private func resolve() {
        DispatchQueue.main.async { self.onResolve() }
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
