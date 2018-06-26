import MGSwipeTableCell

protocol NotificationAction: CustomStringConvertible {
    func identifier() -> Identifier
    func execute()
    func setOn()
    func setOff()

    var enabled: Bool { get }
    var icon: UIButton? { get }
}

extension NotificationAction {
    func execute() {

    }
}

extension NotificationAction {
    var description: String {
        return identifier().description + " enabled \(enabled)"
    }
}

class DefaultNotificationAction: NotificationAction {
    let enabled: Bool

    private(set) lazy var mainContext: NSManagedObjectContext? = {
        return ContextManager.sharedInstance().mainContext
    }()

    private(set) lazy var actionsService: NotificationActionsService? = {
        return NotificationActionsService(managedObjectContext: mainContext!)
    }()

    var icon: UIButton? {
        return nil
    }

    init(enabled: Bool) {
        self.enabled = enabled
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
