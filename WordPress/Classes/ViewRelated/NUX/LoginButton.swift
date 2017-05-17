import UIKit
import WordPressShared

/// A stylized button used by Login controllers. It also can display a `UIActivityIndicatorView`.
@objc class LoginButton: UIButton {
    @IBInspectable var isPrimary: Bool = false {
        didSet {
            configureButton()
        }
    }

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
            configureButton()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            configureButton()
        }
    }

    // MARK: - Life Cycle Methods

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
    fileprivate func configureButton() {
        contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        
        titleLabel?.font = WPFontManager.systemSemiBoldFont(ofSize: 17.0)
        
        var backgroundColor = UIColor.clear
        var titleColorNormal = UIColor.white
        var titleColorHighlighted = WPStyleGuide.lightBlue()
        var titleColorDisabled = UIColor(white: 1.0, alpha: NUXSubmitButtonDisabledAlpha)
        let normalImage: UIImage?
        let highlightImage: UIImage?
        if (isPrimary) {
            normalImage = UIImage(named: "beveled-blue-button-down")
            highlightImage = UIImage(named: "beveled-blue-button-down")

            titleColorNormal = WPStyleGuide.wordPressBlue()
            titleColorHighlighted = WPStyleGuide.darkBlue()
            titleColorDisabled = titleColorNormal.withAlphaComponent(NUXSubmitButtonDisabledAlpha)
        } else {
            // TODO: put in white & gray versions here
            normalImage = UIImage(named: "beveled-blue-button-down")
            highlightImage = UIImage(named: "beveled-blue-button-down")
        }

        if let normalImage = normalImage,
            let highlightImage = highlightImage {
            setBackgroundImage(normalImage, for: .normal)
            setBackgroundImage(highlightImage, for: .highlighted)
        }

        setTitleColor(titleColorNormal, for: .normal)
        setTitleColor(titleColorHighlighted, for: .highlighted)
        setTitleColor(titleColorDisabled, for: .disabled)

        addSubview(activityIndicator)
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
        configureButton()
        setNeedsLayout()
    }
}
