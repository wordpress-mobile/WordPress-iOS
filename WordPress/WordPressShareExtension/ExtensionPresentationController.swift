import UIKit

/// Allows certain presented view controllers to request themselves to be
/// presented at full size instead of inset within the container.
protocol ExtensionPresentationTarget {
    var shouldFillContentContainer: Bool { get }
}

class ExtensionPresentationController: UIPresentationController {

    // MARK: - Private Properties

    private var viewFrame = CGRect.zero

    fileprivate var direction: Direction

    fileprivate let dimmingView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Appearance.dimmingViewBGColor
        view.alpha = Constants.zeroAlpha
        return view
    }()

    // MARK: - Initializers

    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, direction: Direction) {
        self.direction = direction
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)

        self.registerKeyboardObservers()
    }

    deinit {
        removeKeyboardObservers()
    }

    // MARK: - Presentation Controller Overrides

    override var frameOfPresentedViewInContainerView: CGRect {
        var frame: CGRect = .zero
        if let containerView = containerView {
            frame.size = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerView.bounds.size)
            frame.origin.x = (containerView.frame.width - frame.width) / 2.0
            frame.origin.y = (containerView.frame.height - frame.height) / 2.0
        }
        return frame
    }

    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        if let target = container as? ExtensionPresentationTarget,
            target.shouldFillContentContainer == true {
            return parentSize
        }

        let widthRatio = traitCollection.verticalSizeClass != .compact ? Appearance.widthRatio : Appearance.widthRatioCompactVertical
        let heightRatio = traitCollection.verticalSizeClass != .compact ? Appearance.heightRatio : Appearance.heightRatioCompactVertical
        return CGSize(width: (parentSize.width * widthRatio), height: (parentSize.height * heightRatio))
    }

    override func containerViewWillLayoutSubviews() {
        defer {
            presentedView?.layer.cornerRadius = Appearance.cornerRadius
            presentedView?.clipsToBounds = true
        }
        guard #available(iOS 13, *) else {
            presentedView?.frame = frameOfPresentedViewInContainerView
            return
        }
        presentedView?.frame = viewFrame
    }

    override func presentationTransitionWillBegin() {
        containerView?.insertSubview(dimmingView, at: 0)
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|[dimmingView]|", options: [], metrics: nil, views: ["dimmingView": dimmingView]))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|[dimmingView]|", options: [], metrics: nil, views: ["dimmingView": dimmingView]))

        viewFrame = frameOfPresentedViewInContainerView

        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = Constants.fullAlpha
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = Constants.fullAlpha
        })
    }

    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = Constants.zeroAlpha
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = Constants.zeroAlpha
        })
    }
}

// MARK: - External Helper Methods

extension ExtensionPresentationController {
    func resetViewUsingKeyboardFrame(_ keyboardFrame: CGRect = .zero) {
        animateForWithKeyboardFrame(keyboardFrame, duration: Constants.defaultAnimationDuration, force: true)
    }
}

// MARK: - Keyboard Handling

private extension ExtensionPresentationController {
    func registerKeyboardObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWasShown(notification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(notification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIResponder.keyboardWillShowNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIResponder.keyboardWillHideNotification,
                                                  object: nil)
    }

    @objc func keyboardWasShown(notification: Notification) {
        let keyboardFrame = notification.keyboardEndFrame() ?? .zero
        let duration = notification.keyboardAnimationDuration() ?? Constants.defaultAnimationDuration
        animateForWithKeyboardFrame(presentedView!.convert(keyboardFrame, from: nil), duration: duration, keyboardWasShown: true)
    }

    @objc func keyboardWillHide (notification: Notification) {
        let keyboardFrame = notification.keyboardEndFrame() ?? .zero
        let duration = notification.keyboardAnimationDuration() ?? Constants.defaultAnimationDuration
        animateForWithKeyboardFrame(presentedView!.convert(keyboardFrame, from: nil), duration: duration)
    }

    func animateForWithKeyboardFrame(_ keyboardFrame: CGRect, duration: Double, force: Bool = false, keyboardWasShown: Bool = false) {
        let presentedFrame = frameOfPresentedViewInContainerView
        let translatedFrame = getTranslationFrame(keyboardFrame: keyboardFrame, presentedFrame: presentedFrame)
        viewFrame = keyboardWasShown ? translatedFrame : frameOfPresentedViewInContainerView
        if force || translatedFrame != presentedFrame {
            UIView.animate(withDuration: duration, animations: {
                self.presentedView?.frame = translatedFrame
            })
        }
    }

    func getTranslationFrame(keyboardFrame: CGRect, presentedFrame: CGRect) -> CGRect {
        let keyboardTopPadding = traitCollection.verticalSizeClass != .compact ? Constants.bottomKeyboardMarginPortrait : Constants.bottomKeyboardMarginLandscape
        let keyboardTop = UIScreen.main.bounds.height - (keyboardFrame.size.height + keyboardTopPadding)
        let presentedViewBottom = presentedFrame.origin.y + presentedFrame.height
        let offset = presentedViewBottom - keyboardTop

        guard offset > 0.0  else {
            return presentedFrame
        }

        let newHeight = presentedFrame.size.height - offset
        let frame = CGRect(x: presentedFrame.origin.x, y: presentedFrame.origin.y, width: presentedFrame.size.width, height: newHeight)
        return frame
    }
}

// MARK: - Constants

private extension ExtensionPresentationController {
    struct Constants {
        static let fullAlpha: CGFloat = 1.0
        static let zeroAlpha: CGFloat = 0.0
        static let defaultAnimationDuration: Double = 0.33
        static let bottomKeyboardMarginPortrait: CGFloat = 8.0
        static let bottomKeyboardMarginLandscape: CGFloat = 4.0
    }

    struct Appearance {
        static let dimmingViewBGColor = UIColor(white: 0.0, alpha: 0.5)
        static let cornerRadius: CGFloat = 13.0
        static let widthRatio: CGFloat = 0.95
        static let widthRatioCompactVertical: CGFloat = 0.91
        static let heightRatio: CGFloat = 0.90
        static let heightRatioCompactVertical: CGFloat = 0.97
    }
}

// MARK: Notification + UIKeyboardInfo

private extension Notification {

    /// Gets the optional CGRect value of the UIKeyboardFrameEndUserInfoKey from a UIKeyboard notification
    func keyboardEndFrame () -> CGRect? {
        return (self.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
    }

    /// Gets the optional AnimationDuration value of the UIKeyboardAnimationDurationUserInfoKey from a UIKeyboard notification
    func keyboardAnimationDuration () -> Double? {
        return (self.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
    }
}
