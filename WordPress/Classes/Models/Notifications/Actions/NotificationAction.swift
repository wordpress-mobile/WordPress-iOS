/// Base Notification Action Command.
class DefaultNotificationActionCommand: FormattableContentActionCommand {
    var on: Bool

    var identifier: Identifier {
        return type(of: self).commandIdentifier()
    }

    var actionTitle: String? {
        return nil
    }

    var actionColor: UIColor? {
        UIAppColor.primary
    }

    private(set) lazy var mainContext: NSManagedObjectContext? = {
        return ContextManager.sharedInstance().mainContext
    }()

    private(set) lazy var actionsService: NotificationActionsService? = {
        return NotificationActionsService(coreDataStack: ContextManager.shared)
    }()

    init(on: Bool) {
        self.on = on
    }

    func execute<ContentType: FormattableContent>(context: ActionContext<ContentType>) { }
}
