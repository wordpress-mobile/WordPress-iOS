import Foundation


/**
*  @class           AlertView
*  @brief           The purpose of this class is to render a simple AlertView, with a custom style,
*                   and the following sections: [ Title, Message, Button ]
*/

public class AlertView : NSObject
{
    // MARK: - Public Aliases
    public typealias Completion = (() -> ())

    
    /**
    *  @details     Designated Initializer
    *  @param       title       The title of the AlertView.
    *  @param       message     Message string to be displayed. Note: Bold is supported, **markdown flavor**.
    *  @param       completion  A closure to be executed right after the button is pressed.
    */
    public init(title: String, message: String, button: String, completion: Completion?) {
        super.init()
        
        NSBundle.mainBundle().loadNibNamed(AlertView.classNameWithoutNamespaces(), owner: self, options: nil)
        
        assert(internalView != nil)
        internalView.titleLabel.text = title
        internalView.descriptionLabel.attributedText = applyMessageStyles(message)
    }
    
    
    
    /**
    *  @details     Displays the AlertView in the window.
    */
    public func show() {
        let targetView = keyView()

        // Attach the BackgroundView
        targetView.endEditing(true)
        targetView.addSubview(internalView)
        
        // We should cover everything
        internalView.setTranslatesAutoresizingMaskIntoConstraints(false)
        targetView.pinSubviewToAllEdges(internalView)
        
        // Animate!
        internalView.fadeInWithAnimation()
        
        // Note:
        // The internalView will retain the AlertView itself. After it's dismissed, everything will
        // be automatically cleaned up!
        internalView?.onClick = {
            self.dismiss()
        }
    }
    
    
    
    /**
    *  @details     Finds the root view attached to the window
    *  @returns     The Key View.
    */
    private func keyView() -> UIView {
        return UIApplication.sharedApplication().keyWindow?.subviews.first as! UIView
    }
    
    
    
    /**
    *  @details     Fades out the AlertView, and, on completion, will cleanup and hit the completion closure.
    */
    private func dismiss() {        
        UIView.animateWithDuration(WPAnimationDurationFast, animations: { () -> Void in
                self.internalView.alpha = WPAlphaZero
            },
            completion: { (success: Bool) -> Void in
                self.internalView.removeFromSuperview()
                self.onCompletion?()
            })
    }
    
    
    
    /**
    *  @details     Apples Bold Style over all of the text surrounded by **double stars** (and removes the markers!).
    *  @param       message     The Message that should be stylized.
    *  @returns                 The Message with Bold Substrings styled.
    */
    private func applyMessageStyles(message: String) -> NSAttributedString {
        let attributedMessage = NSMutableAttributedString(string: message, attributes: Style.detailsRegularAttributes)
        
        // Apply Bold Styles
        let boldPattern = "(\\*{1,2}).+?\\1"
        attributedMessage.applyStylesToMatchesWithPattern(boldPattern, styles: Style.detailsBoldAttributes)
        
        // Replace the Bold Markers
        let range = NSRange(location: 0, length: attributedMessage.length)
        attributedMessage.mutableString.replaceOccurrencesOfString("**",
            withString  : "",
            options     : .CaseInsensitiveSearch,
            range       : range)
        
        return attributedMessage
    }
    
    
    
    // MARK: - Private Aliases
    private typealias Style = WPStyleGuide.AlertView
    
    // MARK: - Private Properties
    private var onCompletion : Completion?
    
    // MARK: - Private Outlets
    @IBOutlet private var internalView : AlertInternalView!
}
