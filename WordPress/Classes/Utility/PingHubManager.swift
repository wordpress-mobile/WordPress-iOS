import Foundation
import PingHub

class PingHubManager: NSObject {
    private var client: PinghubClient? = nil {
        willSet {
            client?.disconnect()
        }
    }

    override init() {
        super.init()
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(PingHubManager.accountChanged), name: WPAccountDefaultWordPressComAccountChangedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PingHubManager.applicationDidEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PingHubManager.applicationWillEnterForeground), name: UIApplicationWillEnterForegroundNotification, object: nil)
        maybeReplaceClient()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    @objc
    func accountChanged() {
        maybeReplaceClient()
    }

    @objc
    func applicationDidEnterBackground() {
        client?.disconnect()
    }

    @objc
    func applicationWillEnterForeground() {
        client?.connect()
    }

    private func maybeReplaceClient() {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        guard let account = service.defaultWordPressComAccount() else {
            return
        }

        client = nil

        guard let token = account.authToken where !token.isEmpty else {
            assertionFailure("Can't create a PingHub client if the account has no auth token")
            return
        }

        client = PinghubClient(token: token)
        client?.delegate = self

        let state = UIApplication.sharedApplication().applicationState
        if state == .Active || state == .Inactive {
            client?.connect()
        }
    }
}

extension PingHubManager: PinghubClientDelegate {
    func pingubConnected(client client: PinghubClient) {
        DDLogSwift.logDebug("PingHub connected")
    }

    func pinghubDisconnected(client client: PinghubClient, error: ErrorType?) {
        DDLogSwift.logDebug("PingHub disconnected")
    }

    func pinghubActionReceived(client client: PinghubClient, action: Action) {
        guard let mediator = NotificationSyncMediator() else {
            return
        }
        switch action {
        case .delete(let noteID):
            DDLogSwift.logDebug("PingHub delete, syncing note \(noteID)")
            mediator.deleteNote(String(noteID))
        case .push(let noteID, _, _, _):
            DDLogSwift.logDebug("PingHub push, syncing note \(noteID)")
            mediator.syncNote(with: String(noteID), completion: { _ in })
        }
    }

    func pinghubUnexpectedDataReceived(client client: PinghubClient, message: String) {
        DDLogSwift.logError(message)
    }
}
