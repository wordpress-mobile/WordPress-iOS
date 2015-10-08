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
}
