import UIKit
import WordPressShared

/// A stylized button used by Login controllers. It also can display a `UIActivityIndicatorView`.
@objc open class NUXButton: NUXSubmitButton {
    // MARK: - Configuration
    fileprivate let horizontalInset: CGFloat = 20
    fileprivate let verticalInset: CGFloat = 12
    fileprivate let maxFontSize: CGFloat = 22

    /// Configure the appearance of the button.
    ///
    override open func configureButton() {
        contentEdgeInsets = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)

        titleLabel?.font = WPStyleGuide.fontForTextStyle(.headline, maximumPointSize: maxFontSize)
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.textAlignment = .center

        let normalImage: UIImage?
        let highlightImage: UIImage?
        let titleColorNormal: UIColor
        if isPrimary {
            normalImage = UIImage(named: "beveled-blue-button")
            highlightImage = UIImage(named: "beveled-blue-button-down")

            titleColorNormal = UIColor.white
        } else {
            normalImage = UIImage(named: "beveled-secondary-button")
            highlightImage = UIImage(named: "beveled-secondary-button-down")

            titleColorNormal = WPStyleGuide.darkGrey()
        }
        let disabledImage = UIImage(named: "beveled-disabled-button")
        let titleColorDisabled = WPStyleGuide.greyLighten30()

        setBackgroundImage(normalImage, for: .normal)
        setBackgroundImage(highlightImage, for: .highlighted)
        setBackgroundImage(disabledImage, for: .disabled)

        setTitleColor(titleColorNormal, for: .normal)
        setTitleColor(titleColorNormal, for: .highlighted)
        setTitleColor(titleColorDisabled, for: .disabled)

        activityIndicator.activityIndicatorViewStyle = .gray

        addSubview(activityIndicator)
    }

    override open func configureBorderColor() {
    }
}
