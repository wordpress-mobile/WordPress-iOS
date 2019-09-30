import Foundation
import CocoaLumberjack
import Reachability

// This is added as a top level function to avoid cluttering PingHubManager.init
private func defaultAccountToken() -> String? {
    let context = ContextManager.sharedInstance().mainContext
    let service = AccountService(managedObjectContext: context)
    guard let account = service.defaultWordPressComAccount() else {
        return nil
    }
    guard let token = account.authToken, !token.isEmpty else {
        return nil
    }
    return token
}

/// PingHubManager will attempt to keep a PinghubClient connected as long as it
/// is alive while certain conditions are met.
///
/// # When it connects
///
/// The manager will try to connect as long as it has an oAuth2 token and the
/// app is in the foreground.
///
/// When a connection fails for some reason, it will try to reconnect whenever
/// there is an internet connection, as detected by Reachability. If the app
/// thinks it's online but connections are still failing, the manager adds an
/// increasing delay to the reconnection to avoid too many attempts.
///
/// # Debugging
///
/// There are a couple helpers to aid with debugging the manager.
///
/// First, if you want to see a detailed log of every state changed and the
/// resulting action in the console, add `-debugPinghub` to the arguments passed
/// on launch in Xcode's scheme editor.
///
/// Second, if you want to simulate some network error conditions to test the
/// retry algorithm, you can set a breakpoint in any Swift code, and enter into
/// the LLDB prompt:
///
///     expr PinghubClient.Debug.simulateUnreachableHost(true)
///
/// This will simulate a "Unreachable Host" error every time the PingHub client
/// tries to connect. If you want to disable it, do the same thing but passing
/// `false`.
///
class PingHubManager: NSObject {
    enum Configuration {
        /// Sequence of increasing delays to apply to the retry mechanism (in seconds)
        ///
        static let delaySequence = [1, 2, 5, 15, 30]

        /// Enables manager during tests
        ///
        static let enabledDuringTests = false
    }

    fileprivate typealias StatePattern = Pattern<State>
    fileprivate struct State {
        // Connected or connecting
        var connected: Bool
        var reachable: Bool
        var foreground: Bool
        var authToken: String?

        enum Pattern {
            static let connected: StatePattern = { $0.connected }
            static let reachable: StatePattern = { $0.reachable }
            static let foreground: StatePattern = { $0.foreground }
            static let loggedIn: StatePattern = { $0.authToken != nil }
        }
    }

    fileprivate var client: PinghubClient? = nil {
        willSet {
            client?.disconnect()
        }
    }

    fileprivate let reachability: Reachability = Reachability.forInternetConnection()
    fileprivate var state: State {
        didSet {
            stateChanged(old: oldValue, new: state)
        }
    }
    fileprivate var delay = IncrementalDelay(Configuration.delaySequence)
    fileprivate var delayedRetry: DispatchDelayedAction?


    override init() {
        let foreground = (UIApplication.shared.applicationState != .background)
        let authToken = defaultAccountToken()
        state = State(connected: false, reachable: reachability.isReachable(), foreground: foreground, authToken: authToken)
        super.init()

        guard enabled else {
            return
        }

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(PingHubManager.accountChanged), name: .WPAccountDefaultWordPressComAccountChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PingHubManager.applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PingHubManager.applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        if let token = authToken {
            client = client(token: token)
            // Simulate state change to figure out if we should try to connect
            stateChanged(old: state, new: state)
        }

        setupReachability()
    }

    deinit {
        delayedRetry?.cancel()
        reachability.stopNotifier()
    }

    fileprivate func stateChanged(old: State, new: State) {
        precondition(Thread.isMainThread, "PingHubManager should only be changing state from the main thread")

        let connected = State.Pattern.connected
        let disconnected = !connected
        let foreground = State.Pattern.foreground
        let loggedIn = State.Pattern.loggedIn
        let reachable = State.Pattern.reachable
        let connectionAllowed = loggedIn & foreground
        let connectionNotAllowed = !connectionAllowed
        let reconnectable = reachable & foreground & loggedIn

        func debugLog(_ message: String) {
            Debug.logStateChange(from: old, to: new, message: message)
        }

        switch (old, new) {
        case (_, connected & !connectionAllowed):
            debugLog("disconnect")
            disconnect()
        case (disconnected, disconnected & reconnectable):
            debugLog("reconnect")
            delay.reset()
            connect()
        case (connected, disconnected & reconnectable):
            debugLog("reconnect delayed (\(delay.current)s)")
            connectDelayed()
        case (connectionNotAllowed, disconnected & connectionAllowed):
            debugLog("connect")
            connect()
        default:
            debugLog("nothing to do")
            break
        }
    }

    fileprivate func client(token: String) -> PinghubClient {
        let client = PinghubClient(token: token)
        client.delegate = self
        return client
    }

    private var enabled: Bool {
        return !UIApplication.shared.isRunningTestSuite() || Configuration.enabledDuringTests
    }
}


// MARK: - Inputs
fileprivate extension PingHubManager {

    // MARK: loggedIn
    @objc
    func accountChanged() {
        let authToken = defaultAccountToken()
        DispatchQueue.main.async { [weak self] in
            self?.resetAuthToken(authToken)
        }
    }

    func resetAuthToken(_ authToken: String?) {
        client = authToken.map({ client(token: $0 ) })
        // we set a new state as we are changing two properties and only want to trigger didSet once
        state = State(connected: false, reachable: state.reachable, foreground: state.foreground, authToken: authToken)
    }

    // MARK: foreground
    @objc
    func applicationDidEnterBackground() {
        state.foreground = false
    }

    @objc
    func applicationWillEnterForeground() {
        state.foreground = true
    }

    // MARK: reachability
    func setupReachability() {
        let reachabilityChanged: (Reachability?) -> Void = { [weak self] reachability in
            guard let manager = self, let reachability = reachability else {
                return
            }
            DispatchQueue.main.async {
                manager.state.reachable = reachability.isReachable()
            }
        }
        reachability.reachableBlock = reachabilityChanged
        reachability.unreachableBlock = reachabilityChanged
        reachability.startNotifier()
    }
}

// MARK: - Actions
fileprivate extension PingHubManager {
    func connect() {
        guard !state.connected else {
            return
        }
        state.connected = true
        DDLogInfo("PingHub connecting")
        client?.connect()
    }

    func connectDelayed() {
        delayedRetry = DispatchDelayedAction(delay: .seconds(delay.current)) { [weak self] in
            self?.connect()
        }
        delay.increment()
    }

    func disconnect() {
        delayedRetry?.cancel()
        DDLogInfo("PingHub disconnecting")
        client?.disconnect()
        state.connected = false
    }
}

extension PingHubManager: PinghubClientDelegate {
    func pingubDidConnect(_ client: PinghubClient) {
        DDLogInfo("PingHub connected")
        delay.reset()
        state.connected = true
        // Trigger a full sync, since we might have missed notes while PingHub was disconnected
        NotificationSyncMediator()?.sync()
    }

    func pinghubDidDisconnect(_ client: PinghubClient, error: Error?) {
        if let error = error {
            DDLogError("PingHub disconnected: \(error)")
        } else {
            DDLogInfo("PingHub disconnected")
        }
        state.connected = false
    }

    func pinghub(_ client: PinghubClient, actionReceived action: PinghubClient.Action) {
        guard let mediator = NotificationSyncMediator() else {
            return
        }
        switch action {
        case .delete(let noteID):
            DDLogInfo("PingHub delete, syncing note \(noteID)")
            mediator.deleteNote(noteID: String(noteID))
        case .push(let noteID, _, _, _):
            DDLogInfo("PingHub push, syncing note \(noteID)")
            mediator.syncNote(with: String(noteID))
        }
    }

    func pinghub(_ client: PinghubClient, unexpected message: PinghubClient.Unexpected) {
        DDLogError(message.description)
    }
}

extension PingHubManager {
    // Functions to aid debugging.
    // It might not be my prettiest code, but it is meant to be ephemeral like a rainbow.

    fileprivate enum Debug {
        static func diff(_ lhs: State, _ rhs: State) -> String {
            func b(_ b: Bool) -> String {
                return b ? "Y" : "N"
            }

            var diff = [String]()
            if lhs.connected != rhs.connected {
                diff.append("conn: \(b(lhs.connected)) -> \(b(rhs.connected))")
            } else {
                diff.append("conn: \(b(rhs.connected))")
            }
            if lhs.reachable != rhs.reachable {
                diff.append("reach: \(b(lhs.reachable)) -> \(b(rhs.reachable))")
            } else {
                diff.append("reach: \(b(rhs.reachable))")
            }
            if lhs.foreground != rhs.foreground {
                diff.append("fg: \(b(lhs.foreground)) -> \(b(rhs.foreground))")
            } else {
                diff.append("fg: \(b(rhs.foreground))")
            }
            if lhs.authToken != rhs.authToken {
                diff.append("log: \(b(lhs.authToken != nil)) -> \(b(rhs.authToken != nil)))")
            } else {
                diff.append("log: \(b(rhs.authToken != nil))")
            }
            return "(" + diff.joined(separator: ", ") + ")"
        }

        static func logStateChange(from old: State, to new: State, message: String) {
            // To enable debugging, add `-debugPinghub` to the launch arguments
            // in Xcode's scheme editor
            guard CommandLine.arguments.contains("-debugPinghub") else {
                return
            }
            let diffMessage = diff(old, new)
            DDLogInfo("PingHub state changed \(diffMessage), \(message)")
        }
    }
}
