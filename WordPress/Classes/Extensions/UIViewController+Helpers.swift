import Foundation


extension UIViewController
{
    // Determines if the current ViewController's View is visible and onscreen
    //
    public func isViewOnScreen() -> Bool {
        let visibleAsRoot       = view.window?.rootViewController == self
        let visibleAsTopOnStack = navigationController?.topViewController == self && view.window != nil
        let visibleAsPresented  = view.window?.rootViewController?.presentedViewController == self
        
        return visibleAsRoot || visibleAsTopOnStack || visibleAsPresented
    }
    
    // Determines if the current ViewController is being presented modally
    //
    public func isModal() -> Bool {
        return self.presentingViewController != nil
    }
    
    // Determines if the current ViewController is the only one in the Navigation stack
    //
    public func isRootInNavigation() -> Bool {
        return navigationController?.viewControllers.count == 1
    }
}
