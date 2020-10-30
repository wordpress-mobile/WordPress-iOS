import Foundation

@objc
extension UITextField {

    /// This method takes care of resolving whether the iOS version is vulnerable to the Bulgarian / Icelandic keyboard crash issue
    /// by Apple.  Once the issue is resolved by Apple we should consider setting an upper iOS version to limit this workaround.
    ///
    /// Once we drop support for iOS 14, we could remove this extension entirely.
    ///
    public class func shouldActivateWorkaroundForBulgarianKeyboardCrash() -> Bool {
        if #available(iOS 14.0, *) {
            return true
        }

        return false
    }

    /// We're swizzling `UITextField.becomeFirstResponder()` so that we can fix an issue with
    /// Bulgarian and Icelandic keyboards when appropriate.
    ///
    /// Ref: https://github.com/wordpress-mobile/WordPress-iOS/issues/15187
    ///
    @objc
    class func activateWorkaroundForBulgarianKeyboardCrash() {
        guard let original = class_getInstanceMethod(
                UITextField.self,
                #selector(UITextField.becomeFirstResponder)),
              let new = class_getInstanceMethod(
                UITextField.self,
                #selector(UITextField.swizzledBecomeFirstResponder)) else {

            DDLogError("Could not activate workaround for Bulgarian keyboard crash.")

            return
        }

        method_exchangeImplementations(original, new)
    }

    /// This method simply replaces the `returnKeyType == .continue` with
    /// `returnKeyType == .next`when the Bulgarian Keyboard crash workaround is needed.
    ///
    public func swizzledBecomeFirstResponder() {
        if UITextField.shouldActivateWorkaroundForBulgarianKeyboardCrash(),
           returnKeyType == .continue {
            returnKeyType = .next
        }

        // This can look confusing - it's basically calling the original method to
        // make sure we don't disrupt anything.
        swizzledBecomeFirstResponder()
    }
}
