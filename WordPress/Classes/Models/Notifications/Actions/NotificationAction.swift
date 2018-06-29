import MGSwipeTableCell

class DefaultNotificationAction: FormattableContentAction {
    var enabled: Bool

    var on: Bool

    var identifier: Identifier {
        return type(of: self).actionIdentifier()
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

    init(on: Bool) {
        self.on = on
        self.enabled = true
    }

    func execute(context: ActionContext) { }
}
