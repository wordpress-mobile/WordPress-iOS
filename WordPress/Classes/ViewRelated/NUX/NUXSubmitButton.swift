import UIKit
import WordPressShared

@objc class NUXSubmitButton : UIButton
{
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


    ///
    ///
    func configureButton() {
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)

        let cornerRadius = CGFloat(5.0)
        layer.cornerRadius = cornerRadius
        layer.borderWidth = 2
        layer.borderColor = UIColor.whiteColor().CGColor

        titleLabel?.font = WPFontManager.systemRegularFontOfSize(18.0)
        setTitleColor(UIColor.whiteColor(), forState: .Normal)
        setTitleColor(UIColor(white: 1.0, alpha: 0.5), forState: .Disabled)


        let capInsets = UIEdgeInsets(top: cornerRadius, left: cornerRadius, bottom: cornerRadius, right: cornerRadius)
        let normalImage = UIImage(color: WPStyleGuide.wordPressBlue(), havingSize: CGSize(width: 44, height: 44))
        let highlightImage = UIImage(color: UIColor.whiteColor(), havingSize: CGSize(width: 44, height: 44))

        setBackgroundImage(normalImage.resizableImageWithCapInsets(capInsets), forState: .Normal)
        setBackgroundImage(highlightImage.resizableImageWithCapInsets(capInsets), forState: .Highlighted)

        addSubview(activityIndicator)
    }


    ///
    ///
    func configureBorderColor() {
        let color = enabled || activityIndicator.isAnimating() ? UIColor.whiteColor() : UIColor(white: 1.0, alpha: 0.5)
        layer.borderColor = color.CGColor
    }


    // MARK: - Instance Methods


    ///
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