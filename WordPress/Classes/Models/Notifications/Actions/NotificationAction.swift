/// Base Notification Action Command
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

    var icon: UIButton? {
        return nil
    }

    init(on: Bool) {
        self.on = on
    }

    func execute(context: ActionContext) { }

    func setIconStrings(title: String, label: String = "", hint: String = "") {
        setIconTitle(title)
        setAccessibilityLabel(label)
        setAccessibilityHint(hint)
    }

    private func setIconTitle(_ title: String) {
        icon?.setTitle(title, for: .normal)
    }

    private func setAccessibilityLabel(_ label: String) {
        icon?.accessibilityLabel = label
    }

    private func setAccessibilityHint(_ hint: String) {
        icon?.accessibilityHint = hint
    }
}
