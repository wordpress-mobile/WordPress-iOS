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
    @IBOutlet weak var headerImageViewWrapperBottomConstraint: NSLayoutConstraint?
    @IBOutlet weak var headerImageWrapperView: UIView!

    /// Title
    ///
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleAccessoryButtonTrailingConstraint: NSLayoutConstraint!

    /// Body
    ///
    @IBOutlet weak var bodyLabel: UILabel!

    /// Dividers
    ///
    @IBOutlet weak var topDividerView: UIView!
    @IBOutlet weak var bottomDividerView: UIView!

    /// Buttons!
    ///
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var defaultButton: UIButton!
    @IBOutlet weak var moreInfoButton: UIButton!
    @IBOutlet weak var titleAccessoryButton: UIButton!

    /// Buttons: Wrapper Views
    ///
    @IBOutlet weak var buttonStackView: UIStackView!
    @IBOutlet weak var buttonWrapperView: UIView!
    @IBOutlet weak var buttonWrapperViewTopConstraint: NSLayoutConstraint?

    /// Wraps the entire view to give it a background and rounded corners
    ///
    @IBOutlet weak var wrapperView: UIView!

    /// All of the content Views
    ///
    @IBOutlet var contentViews: [UIView]!



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
    @objc public dynamic var actionsFont: UIFont? {
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
}
