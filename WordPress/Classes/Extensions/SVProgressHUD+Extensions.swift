import SVProgressHUD

extension SVProgressHUD {
    @objc public class func showDismissibleError(status: String) {
        registerForHUDNotifications()
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.showError(withStatus: status)
    }

    @objc public class func showDismissibleSuccess(status: String) {
        registerForHUDNotifications()
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.showSuccess(withStatus: status)
    }

    static func registerForHUDNotifications() {
        // Remove existing observers to prevent duplicates
        unregisterFromHUDNotifications()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHUDTappedNotification),
            name: NSNotification.Name.SVProgressHUDDidReceiveTouchEvent,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHUDDisappearedNotification),
            name: NSNotification.Name.SVProgressHUDWillDisappear,
            object: nil
        )
    }

    static func unregisterFromHUDNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.SVProgressHUDDidReceiveTouchEvent, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.SVProgressHUDWillDisappear, object: nil)
    }

    @objc static func handleHUDTappedNotification(_ notification: Notification) {
        SVProgressHUD.dismiss()
    }

    @objc static func handleHUDDisappearedNotification(_ notification: Notification) {
        // Prevent unregistering if another HUD is still visible
        if !SVProgressHUD.isVisible() {
            unregisterFromHUDNotifications()
        }
    }
}
