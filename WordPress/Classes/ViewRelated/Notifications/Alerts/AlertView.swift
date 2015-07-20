import Foundation


public class AlertView : NSObject
{
    public typealias Completion = (() -> ())
    
    public init(title: String, message: String, button: String, completion: Completion?) {
        super.init()
        
        // Load the nib
        NSBundle.mainBundle().loadNibNamed(AlertView.classNameWithoutNamespaces(), owner: self, options: nil)
        
        // Check the Outlets
        assert(backgroundView   != nil)
        assert(alertView        != nil)
        assert(titleLabel       != nil)
        assert(descriptionLabel != nil)
        
        // Setup please!
        alertView.layer.cornerRadius    = cornerRadius
        titleLabel.font                 = Styles.titleFont
        descriptionLabel.font           = Styles.detailsFont
        
        titleLabel.textColor            = Styles.titleColor
        descriptionLabel.textColor      = Styles.detailsColor
        
        titleLabel.text                 = title
        descriptionLabel.text           = message

        dismissButton.titleLabel?.font  = Styles.buttonFont
// TODO
//  1. Completion Callback
//  2. Document please
//  3. Who retains / releases this view?
//  4. Semi-bold the key words in the numbered steps
    }
    
    public func show() {
        let targetView = keyView()

        // Attach the BackgroundView
        targetView.endEditing(true)
        targetView.addSubview(backgroundView)
        
        // We should cover everything
        backgroundView.setTranslatesAutoresizingMaskIntoConstraints(false)
        targetView.pinSubviewToAllEdges(backgroundView)
        
        // Animate!
        backgroundView.fadeInWithAnimation()
    }
    
    
    // MARK: - Private Helpers
    private func keyView() -> UIView {
        return UIApplication.sharedApplication().keyWindow?.subviews.first as! UIView
    }
    
    @IBAction private func buttonWasPressed(sender: AnyObject!) {
        let animationDuration = NSTimeInterval(0.3)
        let finalAlpha = CGFloat(0)
        
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
                self.backgroundView.alpha = finalAlpha
            },
            completion: { (success: Bool) -> Void in
                self.backgroundView.removeFromSuperview()
                self.onCompletion?()
            })
    }
    

    // MARK: - Private Aliases
    private typealias Styles = WPStyleGuide.AlertView
    
    // MARK: - Private Constants
    private let cornerRadius = CGFloat(7)
    
    // MARK: - Private Properties
    private var onCompletion : Completion?
    
    // MARK: - Private Outlets
    @IBOutlet private var backgroundView    : UIView!
    @IBOutlet private var alertView         : UIView!
    @IBOutlet private var titleLabel        : UILabel!
    @IBOutlet private var descriptionLabel  : UILabel!
    @IBOutlet private var dismissButton     : UIButton!
}
