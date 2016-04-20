import Foundation
import WordPressShared

/**
*  @class           AlertInternalView
*  @brief           Helper class, used internally by AlertView. Not designed for general usage.
*/

public class AlertInternalView : UIView
{
    // MARK: - Public Properties
    public var onClick : (() -> ())?
    
    
    
    // MARK: - View Methods
    public override func awakeFromNib() {
         super.awakeFromNib()
        
        assert(backgroundView   != nil)
        assert(alertView        != nil)
        assert(titleLabel       != nil)
        assert(descriptionLabel != nil)

        alertView.layer.cornerRadius = cornerRadius
        titleLabel.font = Styles.titleRegularFont
        descriptionLabel.font = Styles.detailsRegularFont

        titleLabel.textColor = Styles.titleColor
        descriptionLabel.textColor = Styles.detailsColor

        dismissButton.titleLabel?.font = Styles.buttonFont
    }
    
    
    
    /**
    *  @details     Handles the Dismiss Button Tap.
    *  @param       sender      The button that was pressed.
    */
    @IBAction private func buttonWasPressed(sender: AnyObject!) {
        onClick?()
        onClick = nil
    }
    
    
    
    // MARK: - Private Aliases
    private typealias Styles = WPStyleGuide.AlertView
    
    // MARK: - Private Constants
    private let cornerRadius = CGFloat(7)
    
    // MARK: - Outlets
    @IBOutlet var backgroundView    : UIView!
    @IBOutlet var alertView         : UIView!
    @IBOutlet var titleLabel        : UILabel!
    @IBOutlet var descriptionLabel  : UILabel!
    @IBOutlet var dismissButton     : UIButton!
}
