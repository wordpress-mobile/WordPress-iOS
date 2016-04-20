import Foundation
import WordPressShared.WPStyleGuide

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
        
        let attributedMessage = NSMutableAttributedString(string: message, attributes: Style.detailsRegularAttributes)
        internalView.descriptionLabel.attributedText = removeBoldMarkers(applyBoldStyles(attributedMessage))
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
        internalView.translatesAutoresizingMaskIntoConstraints = false
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
        return (UIApplication.sharedApplication().keyWindow?.subviews.first)!
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
    *  @details     Apples Bold Style over all of the text surrounded by **double stars**.
    *  @param       message     The Message that should be stylized.
    *  @returns                 The Message with Bold Substrings styled.
    */
    private func applyBoldStyles(message: NSMutableAttributedString) -> NSMutableAttributedString {
        let boldPattern = "(\\*{1,2}).+?\\1"
        message.applyStylesToMatchesWithPattern(boldPattern, styles: Style.detailsBoldAttributes)
        return message
    }

    
    
    /**
    *  @details     Removes the Bold Markers from an Attributed String.
    *  @param       message     The Message that should be stylized.
    *  @returns                 The Message without the **bold** markers.
    */
    private func removeBoldMarkers(message: NSMutableAttributedString) -> NSMutableAttributedString {
        let range = NSRange(location: 0, length: message.length)
        message.mutableString.replaceOccurrencesOfString("**",
            withString  : "",
            options     : .CaseInsensitiveSearch,
            range       : range)
        return message
    }
    
    
    
    // MARK: - Private Aliases
    private typealias Style = WPStyleGuide.AlertView
    
    // MARK: - Private Properties
    private var onCompletion : Completion?
    
    // MARK: - Private Outlets
    @IBOutlet private var internalView : AlertInternalView!
}
