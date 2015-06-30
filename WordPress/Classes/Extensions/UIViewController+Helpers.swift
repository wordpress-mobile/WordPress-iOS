import Foundation


extension UIViewController
{
    public func isViewOnScreen() -> Bool {
        let visibleAsRoot       = view.window?.rootViewController == self
        let visibleAsTopOnStack = navigationController?.topViewController == self && view.window != nil
        let visibleAsPresented  = view.window?.rootViewController?.presentedViewController == self
        
        return visibleAsRoot || visibleAsTopOnStack || visibleAsPresented
    }
}
