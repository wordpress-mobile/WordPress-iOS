/// Conform to this protocol to implement common actions for the blogging reminders flow
protocol BloggingRemindersActions: UIViewController {
    func dismiss(from button: BloggingRemindersTracker.Button,
                 screen: BloggingRemindersTracker.Screen,
                 tracker: BloggingRemindersTracker)
}

extension BloggingRemindersActions {
    func dismiss(from button: BloggingRemindersTracker.Button,
                 screen: BloggingRemindersTracker.Screen,
                 tracker: BloggingRemindersTracker) {

        tracker.buttonPressed(button: button, screen: screen)
        dismiss(animated: true, completion: nil)
    }
}
