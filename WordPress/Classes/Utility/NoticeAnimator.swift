import UIKit
import WordPressShared

/// NoticeAnimator is a helper class to animate error messages.
///
/// The error messages show at the top of the target view, and are meant to
/// appear to be attached to a navigation bar. The expected usage is to display
/// offline status or requests taking longer than usual.
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
    let animationDuration   = 0.3
    let minimumHeight       = CGFloat(40)
    let padding             = UIOffset(horizontal: 15, vertical: 20)

    private var noticeLabel: PaddedLabel? = nil
    private var message: String? = nil
    private var showingMessage: Bool {
        return (message != nil)
    }
    private var messageHeight : CGFloat {
        guard let label = noticeLabel?.label, let message = message else {
            return minimumHeight
        }
        
        let height = message.suggestedSizeWithFont(label.font, width: label.frame.width).height + padding.vertical
        return max(round(height), minimumHeight)
    }
    
    let targetView: UIView
    var targetTableView: UITableView? {
        return targetView as? UITableView
    }

    init(target: UIView) {
        targetView = target
        super.init()
    }

    func layout() {
        if let noticeLabel = noticeLabel {
            let errorFrame = noticeLabel.frame
            var frame = targetView.bounds
            frame.size.height = errorFrame.height
            noticeLabel.frame = frame
        }
    }

    func animateMessage(message: String?) {
        let previouslyShowing = showingMessage
        // Are we showing or hiding the message
        self.message = message

        if previouslyShowing != showingMessage {
            animateWithDuration(animationDuration, preamble: preamble, animations: animations, cleanup: cleanup)
        }
        
        if showingMessage {
            noticeLabel?.label.text = message
        }
    }

    private func preamble() {
        if showingMessage {
            noticeLabel = createNoticeLabel()
            targetView.addSubview(noticeLabel!)
            noticeLabel?.frame.size.height = 0
            noticeLabel?.label.alpha = 0
        }

        UIView.performWithoutAnimation { [unowned self] in
            self.targetView.layoutIfNeeded()
        }
    }

    private func animations() {
        if showingMessage {
            noticeLabel?.frame.size.height = messageHeight
            noticeLabel?.label.alpha = 1

            targetTableView?.contentInset.top += messageHeight
            if targetTableView?.contentOffset.y == 0 {
                targetTableView?.contentOffset.y = -messageHeight
            }
        } else {
            noticeLabel?.frame.size.height = 0
            noticeLabel?.label.alpha = 0

            targetTableView?.contentInset.top -= messageHeight
        }
        targetView.layoutIfNeeded()
    }
    
    private func cleanup() {
        if !showingMessage {
            noticeLabel?.removeFromSuperview()
            noticeLabel = nil
        }
    }

    private func createNoticeLabel() -> PaddedLabel {
        let paddedLabel = PaddedLabel()
        paddedLabel.padding.horizontal = padding.horizontal
        paddedLabel.label.textColor = UIColor.whiteColor()
        paddedLabel.backgroundColor = WPStyleGuide.mediumBlue()
        paddedLabel.label.font = WPStyleGuide.regularTextFont()
        paddedLabel.label.numberOfLines = 0
        return paddedLabel
    }
}
