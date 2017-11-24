import Foundation
import WordPressShared


/// Helper class, used internally by AlertView. Not designed for general usage.
///
open class AlertInternalView: UIView {
    // MARK: - Public Properties
    @objc open var onClick : (() -> ())?



    // MARK: - View Methods
    open override func awakeFromNib() {
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



    /// Handles the Dismiss Button Tap.
    ///
    /// - Parameter sender: The button that was pressed.
    ///
    @IBAction fileprivate func buttonWasPressed(_ sender: AnyObject!) {
        onClick?()
        onClick = nil
    }



    // MARK: - Private Aliases
    fileprivate typealias Styles = WPStyleGuide.AlertView

    // MARK: - Private Constants
    fileprivate let cornerRadius = CGFloat(7)

    // MARK: - Outlets
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var alertView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var dismissButton: UIButton!
}
