class DefaultNotificationActionCommand: FormattableContentActionCommand {
    var identifier: Identifier {
        return type(of: self).commandIdentifier()
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

    func execute(context: ActionContext) { }
}
