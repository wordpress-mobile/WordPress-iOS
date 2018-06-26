import MGSwipeTableCell

protocol NotificationAction: Hashable {
    func identifier() -> Identifier
    func execute()
    func enable()
    func disable()
    func setOn()
    func setOff()

    var icon: UIButton? { get }
}

extension NotificationAction {
    var hashValue: Int {
        return identifier().hashValue
    }
}

extension NotificationAction {
    func execute() {

    }
}

class DefaultNotificationAction: NotificationAction {
    static func == (lhs: DefaultNotificationAction, rhs: DefaultNotificationAction) -> Bool {
        return lhs.identifier() == rhs.identifier()
    }

    private(set) lazy var mainContext: NSManagedObjectContext? = {
        return ContextManager.sharedInstance().mainContext
    }()

    private(set) lazy var actionsService: NotificationActionsService? = {
        return NotificationActionsService(managedObjectContext: mainContext!)
    }()

    var icon: UIButton? {
        return nil
    }

    func identifier() -> Identifier {
        let typeAsString = String(describing: type(of: self))
        return Identifier(value: typeAsString)
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
