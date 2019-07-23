/// Base Notification Action Command.
class DefaultNotificationActionCommand: FormattableContentActionCommand {
    var on: Bool

    var identifier: Identifier {
        return type(of: self).commandIdentifier()
    }

    private(set) lazy var mainContext: NSManagedObjectContext? = {
        return ContextManager.sharedInstance().mainContext
    }()

    private(set) lazy var actionsService: NotificationActionsService? = {
        return NotificationActionsService(managedObjectContext: mainContext!)
    }()

    init(on: Bool) {
        self.on = on
    }

    func action(handler: @escaping UIContextualAction.Handler) -> UIContextualAction? {
        return nil
    }

    func execute<ContentType: FormattableContent>(context: ActionContext<ContentType>) { }
}
