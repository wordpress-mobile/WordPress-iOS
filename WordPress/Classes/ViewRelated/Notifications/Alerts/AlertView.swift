import Foundation


public class AlertView : NSObject
{
    public typealias Completion = ((buttonIndex: Int) -> ())
    
    public init(title: String, message: String, buttons: [String], completion: Completion?) {
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
        titleLabel.font                 = WPStyleGuide.AlertView.titleFont
        descriptionLabel.font           = WPStyleGuide.AlertView.detailsFont
        
        titleLabel.textColor            = WPStyleGuide.AlertView.titleColor
        descriptionLabel.textColor      = WPStyleGuide.AlertView.detailsColor
        
        titleLabel.text                 = title
        descriptionLabel.text           = message
    }
    
    public func show() {
        let targetView = keyView()

        // Attach the BackgroundView
        targetView.endEditing(true)
        targetView.addSubview(backgroundView)
        
        // We should cover everything
        backgroundView.setTranslatesAutoresizingMaskIntoConstraints(false)
        targetView.pinSubviewToAllEdges(backgroundView)
    }
    
    
    private func keyView() -> UIView {
        return UIApplication.sharedApplication().keyWindow?.subviews.first as! UIView
    }
    

    // MARK: - Private Constants
    private let cornerRadius = CGFloat(7)
    
    // MARK: - Private Properties
    @IBOutlet private var backgroundView    : UIView!
    @IBOutlet private var alertView         : UIView!
    @IBOutlet private var titleLabel        : UILabel!
    @IBOutlet private var descriptionLabel  : UILabel!
}
