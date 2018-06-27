import MGSwipeTableCell

protocol NotificationAction: CustomStringConvertible {
    func identifier() -> Identifier
    func execute(block: NotificationBlock, onCompletion: ((NotificationDeletionRequest) -> Void)?)
    func setOn()
    func setOff()

    var enabled: Bool { get }
    var on: Bool { get }
    var icon: UIButton? { get }
}

extension NotificationAction {
    func execute(block: NotificationBlock, onCompletion: ((NotificationDeletionRequest) -> Void)? = nil) {

    }
}

extension NotificationAction {
    static func actionIdentifier() -> Identifier {
        return Identifier(value: String(describing: self))
    }
}

extension NotificationAction {
    var description: String {
        return identifier().description + " enabled \(enabled)"
    }
}

class DefaultNotificationAction: NotificationAction {
    var enabled: Bool

    let on: Bool

    private(set) lazy var mainContext: NSManagedObjectContext? = {
        return ContextManager.sharedInstance().mainContext
    }()

    private(set) lazy var actionsService: NotificationActionsService? = {
        return NotificationActionsService(managedObjectContext: mainContext!)
    }()

    var icon: UIButton? {
        return nil
    }

    init(on: Bool) {
        self.on = on
        self.enabled = true
    }

    func identifier() -> Identifier {
        return type(of: self).actionIdentifier()
    }

    func enable() {

    }

    func disable() {

    }

    func setOn() {

    }

    func setOff() {

    }
}
