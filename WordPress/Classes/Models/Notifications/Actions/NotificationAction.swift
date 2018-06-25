import MGSwipeTableCell

protocol NotificationAction {
    func identifier() -> Identifier
    func execute()
    func enable()
    func disable()
    func setOn()
    func setOff()

    var icon: UIButton? { get }
}

extension NotificationAction {
    func execute() {

    }
}

class DefaultNotificationAction: NotificationAction {
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
