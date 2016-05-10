import UIKit
import WordPressShared

/// NoticeAnimator is a helper class to animate error messages.
///
/// The notices show at the top of the target view, and are meant to appear to
/// be attached to a navigation bar. The expected usage is to display offline
/// status or requests taking longer than usual.
///
/// To use an NoticeAnimator, you need to keep a reference to it, and call two
/// methods:
///
///  - `layout()` from your `UIView.layoutSubviews()` or
/// `UIViewController.viewDidLayoutSubviews()`. Failure to do this won't render
/// the animation correctly.
///
///  - `animateMessage(_)` when you want to change the message displayed. Pass
/// nil if you want to hide the error view.
///
class NoticeAnimator: Animator {

    // MARK: - Private Constants
    private struct Defaults {
        static let animationDuration   = 0.3
        static let padding             = UIOffset(horizontal: 15, vertical: 20)
        static let labelFont           = WPStyleGuide.regularTextFont()
    }


    // MARK: - Private properties
    private var previousHeight : CGFloat = 0
    private var message : String? {
        get {
            return noticeLabel.label.text
        }
        set {
            noticeLabel.label.text = newValue
        }
    }


    // MARK: - Private Immutable Properties
    private let targetView : UIView
    private let noticeLabel : PaddedLabel = {
        let label = PaddedLabel()
        label.backgroundColor = WPStyleGuide.mediumBlue()
        label.clipsToBounds = true
        label.padding.horizontal = Defaults.padding.horizontal
        label.label.textColor = UIColor.whiteColor()
        label.label.font = Defaults.labelFont
        label.label.numberOfLines = 0
        return label
    }()


    // MARK: - Private Computed Properties
    private var shouldDisplayMessage : Bool {
        return message != nil
    }
    private var targetTableView: UITableView? {
        return targetView as? UITableView
    }



    // MARK: - Initializers
    init(target: UIView) {
        targetView = target
        super.init()
    }



    // MARK: - Public Methods
    func layout() {
        var targetFrame = targetView.bounds
        targetFrame.size.height = heightForMessage(message)
        noticeLabel.frame = targetFrame
    }

    func animateMessage(message: String?) {
        let shouldAnimate = self.message != message
        self.message = message

        if shouldAnimate {
            animateWithDuration(Defaults.animationDuration, preamble: preamble, animations: animations, cleanup: cleanup)
        }
    }



    // MARK: - Animation Methods
    private func preamble() {
        UIView.performWithoutAnimation { [weak self] in
            self?.targetView.layoutIfNeeded()
        }

        if shouldDisplayMessage == true && noticeLabel.superview == nil {
            targetView.addSubview(noticeLabel)
            noticeLabel.frame.size.height = CGSizeZero.height
            noticeLabel.label.alpha = 0
        }
    }

    private func animations() {
        let height = heightForMessage(message)

        if shouldDisplayMessage {
            // Position + Size + Alpha
            noticeLabel.frame.origin.y = -height
            noticeLabel.frame.size.height = height
            noticeLabel.label.alpha = 1

            // Table Insets + Offset
            targetTableView?.contentInset.top += height - previousHeight
            if targetTableView?.contentOffset.y == 0 {
                targetTableView?.contentOffset.y = -height + previousHeight
            }

        } else {
            // Size + Alpha
            noticeLabel.frame.size.height = CGSizeZero.height
            noticeLabel.label.alpha = 0

            // Table Insets
            targetTableView?.contentInset.top -= previousHeight
        }

        previousHeight = height
    }

    private func cleanup() {
        if shouldDisplayMessage == false {
            noticeLabel.removeFromSuperview()
            previousHeight = CGSizeZero.height
        }
    }



    // MARK: - Helpers
    private func heightForMessage(message : String?) -> CGFloat {
        guard let message = message else {
            return CGSizeZero.height
        }

        let size = message.suggestedSizeWithFont(Defaults.labelFont, width: targetView.frame.width)
        return round(size.height + Defaults.padding.vertical)
    }
}
