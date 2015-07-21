import Foundation


public class AlertView : NSObject
{
    public typealias Completion = (() -> ())

    // MARK: - Initializers
    public init(title: String, message: String, button: String, completion: Completion?) {
        super.init()
        
        // Load the nib
        NSBundle.mainBundle().loadNibNamed(AlertView.classNameWithoutNamespaces(), owner: self, options: nil)
        
        // Check the Outlets
        assert(internalView != nil)

        // Done!
        internalView.titleLabel.text = title
        internalView.descriptionLabel.attributedText = applyMessageStyles(message)
    }
    
    
    
    // MARK: - Public Methods
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
    
    
    
    // MARK: - Private Helpers
    private func keyView() -> UIView {
        return UIApplication.sharedApplication().keyWindow?.subviews.first as! UIView
    }
    
    private func dismiss() {        
        UIView.animateWithDuration(WPAnimationDurationFast, animations: { () -> Void in
                self.internalView.alpha = WPAlphaZero
            },
            completion: { (success: Bool) -> Void in
                self.internalView.removeFromSuperview()
                self.onCompletion?()
            })
    }
    
    
    
    // MARK: - Style Helpers
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
