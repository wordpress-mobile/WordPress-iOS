import Foundation
import UIKit

// MARK: - FancyAlertView
//
open class FancyAlertView: UIView {

    /// Header
    ///
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var headerImageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerImageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerImageViewWrapperTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerImageViewWrapperBottomConstraint: NSLayoutConstraint?
    @IBOutlet weak var headerImageWrapperView: UIView!

    /// Title
    ///
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet var titleAccessoryButtonTrailingConstraint: NSLayoutConstraint!

    /// Body
    ///
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var bodyWrapperView: UIView!

    /// Dividers
    ///
    @IBOutlet weak var topDividerView: UIView!
    @IBOutlet weak var bottomDividerView: UIView!

    /// Buttons!
    ///
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var defaultButton: UIButton!
    @IBOutlet weak var neverButton: UIButton!
    @IBOutlet weak var moreInfoButton: UIButton!
    @IBOutlet weak var titleAccessoryButton: UIButton!

    /// Buttons: Wrapper Views
    ///
    @IBOutlet weak var buttonStackView: UIStackView!
    @IBOutlet weak var buttonWrapperView: UIView!
    @IBOutlet weak var buttonWrapperViewTopConstraint: NSLayoutConstraint?

    /// Switch
    ///
    @IBOutlet weak var bottomSwitch: UISwitch!
    @IBOutlet weak var bottomSwitchLabel: UILabel!
    @IBOutlet weak var bottomSwitchStackView: UIStackView!

    /// Wraps the entire view to give it a background and rounded corners
    ///
    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var wrapperViewHeightConstraint: NSLayoutConstraint!

    /// All of the content Views
    ///
    @IBOutlet var contentViews: [UIView]!

    @IBOutlet weak var mainStackView: UIStackView!

    /// TitleLabel: textColor
    ///
    @objc public dynamic var titleTextColor: UIColor? {
        get {
            return titleLabel.textColor
        }
        set {
            titleLabel.textColor = newValue
        }
    }

    /// BodyLabel: textColor
    ///
    @objc public dynamic var bodyTextColor: UIColor? {
        get {
            return bodyLabel.textColor
        }
        set {
            bodyLabel.textColor = newValue
        }
    }

    /// BodyWrapper: backgroundColor
    ///
    @objc public dynamic var bodyBackgroundColor: UIColor? {
        get {
            return bodyWrapperView.backgroundColor
        }
        set {
            bodyWrapperView.backgroundColor = newValue
        }
    }

    /// TitleLabel: Font
    ///
    @objc public dynamic var titleFont: UIFont? {
        get {
            return titleLabel.font
        }
        set {
            titleLabel.font = newValue
        }
    }

    /// BodyLabel: Font
    ///
    @objc public dynamic var bodyFont: UIFont? {
        get {
            return bodyLabel.font
        }
        set {
            bodyLabel.font = newValue
        }
    }

    /// TopDivider: backgroundColor
    ///
    @objc public dynamic var topDividerColor: UIColor? {
        get {
            return topDividerView.backgroundColor
        }
        set {
            topDividerView.backgroundColor = newValue
        }
    }

    /// BottomDivider: backgroundColor
    ///
    @objc public dynamic var bottomDividerColor: UIColor? {
        get {
            return bottomDividerView.backgroundColor
        }
        set {
            bottomDividerView.backgroundColor = newValue
        }
    }

    /// Action Button(s) Font
    ///
    @objc public dynamic var actionFont: UIFont? {
        get {
            return defaultButton.titleLabel?.font
        }
        set {
            defaultButton.titleLabel?.font = newValue
            cancelButton.titleLabel?.font = newValue
        }
    }

    /// MoreInfo: Font
    ///
    @objc public dynamic var infoFont: UIFont? {
        get {
            return moreInfoButton.titleLabel?.font
        }
        set {
            moreInfoButton.titleLabel?.font = newValue
            moreInfoButton.titleLabel?.adjustsFontForContentSizeCategory = true
        }
    }

    /// MoreInfo: tintColor
    ///
    @objc public dynamic var infoTintColor: UIColor? {
        get {
            return moreInfoButton.tintColor
        }
        set {
            moreInfoButton.tintColor = newValue
        }
    }

    /// HeaderImage: backgroundColor
    ///
    @objc public dynamic var headerBackgroundColor: UIColor? {
        get {
            return headerImageWrapperView.backgroundColor
        }
        set {
            headerImageWrapperView.backgroundColor = newValue
        }
    }

    /// ButtonWrapper: backgroundColor
    ///
    @objc public dynamic var bottomBackgroundColor: UIColor? {
        get {
            return buttonWrapperView.backgroundColor
        }
        set {
            buttonWrapperView.backgroundColor = newValue
        }
    }

    /// Switches the button ButtonStackView's layout, if needed.
    ///
    func updateButtonLayout() {
        if defaultButton.intrinsicContentSize.width > defaultButton.bounds.width || cancelButton.intrinsicContentSize.width > cancelButton.bounds.width {
            buttonStackView.axis = .vertical
        }
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // At the beginning of your implementation, call super to ensure that interface elements higher in the view hierarchy have an opportunity to adjust their layout first
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            preferredContentSizeDidChange()
        }
    }

    func preferredContentSizeDidChange() {
        if #available(iOS 11.0, *) {
            if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
                bottomSwitchStackView.axis = .vertical
            } else {
                bottomSwitchStackView.axis = .horizontal
            }
        }
    }
}
