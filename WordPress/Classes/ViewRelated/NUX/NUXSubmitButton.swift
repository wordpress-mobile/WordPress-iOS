import UIKit
import WordPressShared

let NUXSubmitButtonDisabledAlpha = CGFloat(0.25)

/// A stylized button used by NUX controllers. The button presents white text
/// surrounded by a white border.  It also can display a `UIActivityIndicatorView`.
///
@IBDesignable
@objc class NUXSubmitButton : UIButton
{
    @IBInspectable var isPrimary: Bool = false {
        didSet {
            configureButton()
        }
    }
    let cornerRadius = CGFloat(5.0)

    var isAnimating: Bool {
        get {
            return activityIndicator.isAnimating
        }
    }

    let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        indicator.hidesWhenStopped = true
        return indicator
    }()


    override var isEnabled: Bool {
        didSet {
            configureBorderColor()
        }
    }


    override var isHighlighted: Bool {
        didSet {
            configureBorderColor()
        }
    }


    // MARK: - LifeCycle Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        configureButton()
    }


    override func layoutSubviews() {
        super.layoutSubviews()

        if activityIndicator.isAnimating {
            titleLabel?.frame = CGRect.zero

            var frm = activityIndicator.frame
            frm.origin.x = (frame.width - frm.width) / 2.0
            frm.origin.y = (frame.height - frm.height) / 2.0
            activityIndicator.frame = frm
        }
    }


    // MARK: - Configuration


    /// Configure the appearance of the configure button.
    ///
    func configureButton() {
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)

        layer.cornerRadius = cornerRadius
        layer.borderWidth = 1
        layer.borderColor = UIColor.whiteColor().CGColor
        clipsToBounds = true

        titleLabel?.font = WPFontManager.systemSemiBoldFontOfSize(17.0)

        let capInsets = UIEdgeInsets(top: cornerRadius, left: cornerRadius, bottom: cornerRadius, right: cornerRadius)
        var backgroundColor = UIColor.clearColor()
        var titleColorNormal = UIColor.whiteColor()
        var titleColorHighlighted = WPStyleGuide.lightBlue()
        var titleColorDisabled = UIColor(white: 1.0, alpha: NUXSubmitButtonDisabledAlpha)
        if (isPrimary) {
            backgroundColor = UIColor.whiteColor()
            titleColorNormal = WPStyleGuide.wordPressBlue()
            titleColorHighlighted = WPStyleGuide.darkBlue()
            titleColorDisabled = titleColorNormal.colorWithAlphaComponent(NUXSubmitButtonDisabledAlpha)
        }
        let normalImage = UIImage(color: backgroundColor, havingSize: CGSize(width: 44, height: 44))
        setBackgroundImage(normalImage.resizableImageWithCapInsets(capInsets), forState: .Normal)
        setBackgroundImage(normalImage.resizableImageWithCapInsets(capInsets), forState: .Highlighted)

        setTitleColor(titleColorNormal, forState: .Normal)
        setTitleColor(titleColorHighlighted, forState: .Highlighted)
        setTitleColor(titleColorDisabled, forState: .Disabled)

        addSubview(activityIndicator)
    }


    /// Configures the border color.
    ///
    func configureBorderColor() {
        var color: UIColor
        if isEnabled {
            color = isHighlighted ? WPStyleGuide.lightBlue() : UIColor.white
        } else {
            color = UIColor(white: 1.0, alpha: NUXSubmitButtonDisabledAlpha)
        }
        layer.borderColor = color.cgColor
    }


    // MARK: - Instance Methods


    /// Toggles the visibility of the activity indicator.  When visible the button
    /// title is hidden.
    ///
    /// - Parameter show: True to show the spinner. False hides it.
    ///
    func showActivityIndicator(_ show: Bool) {
        if show {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        configureBorderColor()
        setNeedsLayout()
    }
}
