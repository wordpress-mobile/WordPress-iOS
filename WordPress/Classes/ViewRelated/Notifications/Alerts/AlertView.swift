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
        
        internalView.titleLabel.text        = title
        internalView.descriptionLabel.text  = message

// TODO: Semi-bold the key words in the numbered steps
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
        let animationDuration = NSTimeInterval(0.3)
        let finalAlpha = CGFloat(0)
        
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
                self.internalView.alpha = finalAlpha
            },
            completion: { (success: Bool) -> Void in
                self.internalView.removeFromSuperview()
                self.onCompletion?()
            })
    }
    
    
    
    // MARK: - Private Properties
    private var onCompletion : Completion?
    
    // MARK: - Private Outlets
    @IBOutlet private var internalView : AlertInternalView!
}
