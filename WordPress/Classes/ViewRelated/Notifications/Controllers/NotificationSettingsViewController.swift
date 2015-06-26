import Foundation


public class NotificationSettingsViewController : UITableViewController
{
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title
        title = NSLocalizedString("Settings", comment: "Title displayed in the Notification settings")
        
        // Setup Interface
        setupDismissButton()
    }
    
    
    // MARK: - Private Helpers
    private func setupDismissButton() {
        let title  = NSLocalizedString("Close", comment: "Close the currrent screen. Action")
        let action = Selector("dismissWasPressed:")

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: title, style: .Plain, target: self, action: action)
    }

    
    // MARK: - Button Handlers
    public func dismissWasPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
