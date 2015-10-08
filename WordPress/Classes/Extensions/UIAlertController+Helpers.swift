import Foundation


extension UIAlertController
{
    public func addCancelActionWithTitle(title: String?, handler: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        return addActionWithTitle(title, style: .Cancel, handler: handler)
    }
    
    public func addDestructiveActionWithTitle(title: String?, handler: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        return addActionWithTitle(title, style: .Destructive, handler: handler)
    }

    public func addDefaultActionWithTitle(title: String?, handler: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        return addActionWithTitle(title, style: .Default, handler: handler)
    }
    
    public func addActionWithTitle(title: String?, style: UIAlertActionStyle, handler: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        let action = UIAlertAction(title: title, style: style, handler: handler)
        addAction(action)
        
        return action
    }
    
    public func presentFromRootViewController() {
        // Warning: Attempt to present <UIAlertController: 0x7f987c637bd0> on <WordPress.NotificationSettingDetailsViewController: 0x7f987a44e640> whose view is not in the window hierarchy!
        let rootViewController = UIApplication.sharedApplication().delegate?.window??.rootViewController
        rootViewController?.presentViewController(self, animated: true, completion: nil)
    }
}
