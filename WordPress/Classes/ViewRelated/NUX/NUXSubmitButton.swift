import UIKit
import WordPressShared

let NUXSubmitButtonDisabledAlpha = CGFloat(0.25)

/// A stylized button used by NUX controllers. The button presents white text
/// surrounded by a white border.  It also can display a `UIActivityIndicatorView`.
///
@objc class NUXSubmitButton : UIButton
{
    var isAnimating: Bool {
        get {
            return activityIndicator.isAnimating()
        }
    }


    let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
        indicator.hidesWhenStopped = true
        return indicator
    }()


    override var enabled: Bool {
        didSet {
            configureBorderColor()
        }
    }


    override var highlighted: Bool {
        didSet {
            configureBorderColor()
        }
    }


    // MARK: - LifeCycle Methods


    override init(frame: CGRect) {
        super.init(frame: frame)
        configureButton()
    }


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureButton()
    }


    override func layoutSubviews() {
        super.layoutSubviews()

        if activityIndicator.isAnimating() {
            titleLabel?.frame = CGRectZero

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

        let cornerRadius = CGFloat(5.0)
        layer.cornerRadius = cornerRadius
        layer.borderWidth = 1
        layer.borderColor = UIColor.whiteColor().CGColor

        titleLabel?.font = WPFontManager.systemRegularFontOfSize(14.0)
        setTitleColor(UIColor.whiteColor(), forState: .Normal)
        setTitleColor(WPStyleGuide.lightBlue(), forState: .Highlighted)
        setTitleColor(UIColor(white: 1.0, alpha: NUXSubmitButtonDisabledAlpha), forState: .Disabled)

        let capInsets = UIEdgeInsets(top: cornerRadius, left: cornerRadius, bottom: cornerRadius, right: cornerRadius)
        let normalImage = UIImage(color: UIColor.clearColor(), havingSize: CGSize(width: 44, height: 44))

        setBackgroundImage(normalImage.resizableImageWithCapInsets(capInsets), forState: .Normal)
        setBackgroundImage(normalImage.resizableImageWithCapInsets(capInsets), forState: .Highlighted)

        addSubview(activityIndicator)
    }


    /// Configures the border color.
    ///
    func configureBorderColor() {
        var color: UIColor
        if enabled {
            color = highlighted ? WPStyleGuide.lightBlue() : UIColor.whiteColor()
        } else {
            color = UIColor(white: 1.0, alpha: NUXSubmitButtonDisabledAlpha)
        }
        layer.borderColor = color.CGColor
    }


    // MARK: - Instance Methods


    /// Toggles the visibility of the activity indicator.  When visible the button
    /// title is hidden.
    ///
    /// - Parameter show: True to show the spinner. False hides it.
    ///
    func showActivityIndicator(show: Bool) {
        if show {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        configureBorderColor()
        setNeedsLayout()
    }
}
