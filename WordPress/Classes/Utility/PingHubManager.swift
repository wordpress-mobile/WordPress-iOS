import Foundation
import Reachability

private func defaultAccountToken() -> String? {
    let context = ContextManager.sharedInstance().mainContext
    let service = AccountService(managedObjectContext: context)
    guard let account = service?.defaultWordPressComAccount() else {
        return nil
    }
    guard let token = account.authToken, !token.isEmpty else {
        assertionFailure("Can't create a PingHub client if the account has no auth token")
        return nil
    }
    return token
}

class PingHubManager: NSObject {
    fileprivate typealias StatePattern = Pattern<State>
    fileprivate struct State {
        // Connected or connecting
        let connected: Bool
        let reachable: Bool
        let foreground: Bool
        let authToken: String?

        func with(connected: Bool) -> State {
            return State(connected: connected, reachable: reachable, foreground: foreground, authToken: authToken)
        }

        func with(reachable: Bool) -> State {
            return State(connected: connected, reachable: reachable, foreground: foreground, authToken: authToken)
        }

        func with(foreground: Bool) -> State {
            return State(connected: connected, reachable: reachable, foreground: foreground, authToken: authToken)
        }

        func with(authToken: String?) -> State {
            return State(connected: connected, reachable: reachable, foreground: foreground, authToken: authToken)
        }

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


    override init() {
        let foreground = (UIApplication.shared.applicationState != .background)
        let authToken = defaultAccountToken()
        state = State(connected: false, reachable: true, foreground: foreground, authToken: authToken)
        super.init()

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(PingHubManager.accountChanged), name: .WPAccountDefaultWordPressComAccountChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PingHubManager.applicationDidEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PingHubManager.applicationWillEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)

        if let token = authToken {
            client = client(token: token)
            // Simulate state change to figure out if we should try to connect
            stateChanged(old: state, new: state)
        }

        setupReachability()
    }

    deinit {
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self)
    }

    fileprivate func stateChanged(old: State, new: State) {
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
            connect()
        case (connected, disconnected & reconnectable):
            debugLog("reconnect delayed")
            connectDelayed()
        case (connectionNotAllowed, disconnected & connectionAllowed):
            debugLog("connect")
            connect()
        default:
            debugLog("nothing to do")
            break
        }
    }

    func client(token: String) -> PinghubClient {
        let client = PinghubClient(token: token)
        client.delegate = self
        return client
    }
}


// MARK: - Inputs
fileprivate extension PingHubManager {

    // MARK: loggedIn
    @objc
    func accountChanged() {
        let authToken = defaultAccountToken()
        client = authToken.map({ client(token: $0 ) })
        state = state
            .with(authToken: authToken)
            .with(connected: false)
    }

    // MARK: foreground
    @objc
    func applicationDidEnterBackground() {
        state = state.with(foreground: false)
        client?.disconnect()
    }

    @objc
    func applicationWillEnterForeground() {
        state = state.with(foreground: true)
        client?.connect()
    }

    // MARK: reachability
    func setupReachability() {
        let reachabilityChanged: (Reachability?) -> Void = { [weak self] reachability in
            guard let manager = self, let reachability = reachability else {
                return
            }
            manager.state = manager.state.with(reachable: reachability.isReachable())
        }
        reachability.reachableBlock = reachabilityChanged
        reachability.unreachableBlock = reachabilityChanged
        reachability.startNotifier()
    }
}

// MARK: - Actions
fileprivate extension PingHubManager {
    func connect() {
        client?.connect()
        state = state.with(connected: true)
    }

    func connectDelayed() {
        // TODO: Use an actual delay / figure out how to handle failing connections
        connect()
    }

    func disconnect() {
        client?.disconnect()
        state = state.with(connected: false)
    }
}

extension PingHubManager: PinghubClientDelegate {
    func pingubDidConnect(_ client: PinghubClient) {
        DDLogSwift.logInfo("PingHub connected")
        state = state.with(connected: true)
    }

    func pinghubDidDisconnect(_ client: PinghubClient, error: Error?) {
        if let error = error {
            DDLogSwift.logError("PingHub disconnected: \(error)")
        } else {
            DDLogSwift.logInfo("PingHub disconnected")
        }
        state = state.with(connected: false)
    }

    func pinghub(_ client: PinghubClient, actionReceived action: PinghubClient.Action) {
        guard let mediator = NotificationSyncMediator() else {
            return
        }
        switch action {
        case .delete(let noteID):
            DDLogSwift.logInfo("PingHub delete, syncing note \(noteID)")
            mediator.deleteNote(noteID: String(noteID))
        case .push(let noteID, _, _, _):
            DDLogSwift.logInfo("PingHub push, syncing note \(noteID)")
            mediator.syncNote(with: String(noteID), completion: { _ in })
        }
    }

    func pinghub(_ client: PinghubClient, unexpected message: PinghubClient.Unexpected) {
        DDLogSwift.logError(message.description)
    }
}

extension PingHubManager {
    // Functions to aid debugging
    fileprivate enum Debug {
        static func diff(_ lhs: State, _ rhs: State) -> String {
            var diff = [String]()
            if lhs.connected != rhs.connected {
                diff.append("connected: \(lhs.connected) -> \(rhs.connected)")
            } else {
                diff.append("connected: \(rhs.connected)")
            }
            if lhs.reachable != rhs.reachable {
                diff.append("reachable: \(lhs.reachable) -> \(rhs.reachable)")
            } else {
                diff.append("reachable: \(rhs.reachable)")
            }
            if lhs.foreground != rhs.foreground {
                diff.append("foreground: \(lhs.foreground) -> \(rhs.foreground)")
            } else {
                diff.append("foreground: \(rhs.foreground)")
            }
            if lhs.authToken != rhs.authToken {
                diff.append("loggedIn: \(lhs.authToken != nil) -> \(rhs.authToken != nil)")
            } else {
                diff.append("loggedIn: \(rhs.authToken != nil)")
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
            DDLogSwift.logInfo("PingHub state changed \(diffMessage), \(message)")
        }
    }
}
