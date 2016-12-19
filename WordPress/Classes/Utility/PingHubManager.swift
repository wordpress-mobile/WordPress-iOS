import Foundation

class PingHubManager: NSObject {
    private var client: PinghubClient? = nil {
        willSet {
            client?.disconnect()
        }
    }

    override init() {
        super.init()
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(PingHubManager.accountChanged), name: NSNotification.Name.WPAccountDefaultWordPressComAccountChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PingHubManager.applicationDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PingHubManager.applicationWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        replaceClient()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func accountChanged() {
        replaceClient()
    }

    @objc
    func applicationDidEnterBackground() {
        client?.disconnect()
    }

    @objc
    func applicationWillEnterForeground() {
        client?.connect()
    }

    private func replaceClient() {
        client = nil

        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        guard let account = service?.defaultWordPressComAccount() else {
            return
        }

        guard let token = account.authToken, !token.isEmpty else {
            assertionFailure("Can't create a PingHub client if the account has no auth token")
            return
        }

        client = PinghubClient(token: token)
        client?.delegate = self

        let state = UIApplication.shared.applicationState
        if state == .active || state == .inactive {
            client?.connect()
        }
    }
}

extension PingHubManager: PinghubClientDelegate {
    func pingubDidConnect(_ client: PinghubClient) {
        DDLogSwift.logDebug("PingHub connected")
    }

    func pinghubDidDisconnect(_ client: PinghubClient, error: Error?) {
        DDLogSwift.logDebug("PingHub disconnected")
    }

    func pinghub(_ client: PinghubClient, actionReceived action: PinghubClient.Action) {
        guard let mediator = NotificationSyncMediator() else {
            return
        }
        switch action {
        case .delete(let noteID):
            DDLogSwift.logDebug("PingHub delete, syncing note \(noteID)")
            mediator.deleteNote(noteID: String(noteID))
        case .push(let noteID, _, _, _):
            DDLogSwift.logDebug("PingHub push, syncing note \(noteID)")
            mediator.syncNote(with: String(noteID), completion: { _ in })
        }
    }

    func pinghub(_ client: PinghubClient, unexpected message: PinghubClient.Unexpected) {
        DDLogSwift.logError(message.description)
    }
}
