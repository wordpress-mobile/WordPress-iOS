import Foundation
import Combine
import UIKit
import UserNotifications
import WordPressFlux

/// Presents the views of Notices emitted by `NoticeStore`.
///
/// Notices are displayed in 2 ways based on the `UIApplication.state`.
///
/// ## Foreground
///
/// If the app is in the foreground, the Notice is shown as a snackbar-like view inside a separate
/// `UIWindow`. This `UIWindow` is always on top of the main app's `UIWindow`.
///
/// Only one Notice view is displayed at a single time. Queued Notices will be displayed after
/// the current Notice view is dismissed.
///
/// If the `Notice.style.isDismissable` is `true`, the Notice view will be dismissed after a few
/// seconds. This is done by dispatching a `NoticeAction.clear` Action.
///
/// ## Background
///
/// If the app is in the background and the Notice has a `notificationInfo`, a push notification
/// will be sent to the device. If there is no `notificationInfo`, the Notice will be ignored.
///
/// # Usage
///
/// The `NoticePresenter` only needs to be initialized once and kept in memory. After that, it
/// is self-sufficient. You shouldn't need to interact with it directly. In order to display
/// Notices, use `ActionDispatcher` with `NoticeAction` Actions.
///
/// - SeeAlso: `NoticeStore`
/// - SeeAlso: `NoticeAction`
class NoticePresenter {
    /// Used for tracking the currently displayed Notice and its corresponding view.
    private struct NoticePresentation {
        let notice: Notice
        let containerView: NoticeContainerView?
    }
    /// Used to determine if the keyboard is currently shown and what its height is.
    private enum KeyboardPresentation {
        case present(height: CGFloat)
        case notPresent
    }

    private let store: NoticeStore
    private let animator: NoticeAnimator
    private let window: UntouchableWindow
    private var view: UIView {
        guard let view = window.rootViewController?.view else {
            fatalError("Root view controller shouldn't be nil")
        }
        return view
    }

    private let generator = UINotificationFeedbackGenerator()
    private var storeReceipt: Receipt?

    private var currentNoticePresentation: NoticePresentation?
    private var currentKeyboardPresentation: KeyboardPresentation = .notPresent

    private var notificationObservers = Set<AnyCancellable>()

    init(store: NoticeStore = StoreContainer.shared.notice,
         animator: NoticeAnimator = NoticeAnimator(duration: Animations.appearanceDuration, springDampening: Animations.appearanceSpringDamping, springVelocity: NoticePresenter.Animations.appearanceSpringVelocity)) {
        self.store = store
        self.animator = animator

        let windowFrame: CGRect
        if let mainWindow = UIApplication.shared.mainWindow {
            windowFrame = mainWindow.offsetToAvoidStatusBar()
        } else {
            windowFrame = .zero
        }
        window = UntouchableWindow(frame: windowFrame)

        // this window level may affect some UI elements like share sheets.
        // however, since the alerts aren't permanently on screen, this isn't
        // often a problem.
        window.windowLevel = .alert

        // Keep the window visible but hide it on the next run loop. If we hide it immediately,
        // the window is not automatically resized when the device is rotated. This issue
        // only happens on iPad simulators.
        window.isHidden = false
        DispatchQueue.main.async { [weak self] in
            self?.window.isHidden = true
        }

        // Keep the storeReceipt to prevent the `onChange` subscription from being deactivated.
        storeReceipt = store.onChange { [weak self] in
            self?.onStoreChange()
        }

        listenToKeyboardEvents()
        listenToOrientationChangeEvents()
    }

    // MARK: - Events

    private func listenToKeyboardEvents() {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] notification in
                guard let self,
                    let userInfo = notification.userInfo,
                    let keyboardFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
                    let durationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber else {
                        return
                }

                self.currentKeyboardPresentation = .present(height: keyboardFrameValue.cgRectValue.size.height)

                guard let currentContainer = self.currentNoticePresentation?.containerView else {
                    return
                }

                UIView.animate(withDuration: durationValue.doubleValue, animations: {
                    currentContainer.bottomConstraint?.constant = self.onScreenNoticeContainerBottomConstraintConstant
                    self.view.layoutIfNeeded()
                })
            }
            .store(in: &notificationObservers)

        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] notification in
                self?.currentKeyboardPresentation = .notPresent

                guard let self,
                    let currentContainer = self.currentNoticePresentation?.containerView,
                    let userInfo = notification.userInfo,
                    let durationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber else {
                        return
                }

                UIView.animate(withDuration: durationValue.doubleValue, animations: {
                    currentContainer.bottomConstraint?.constant = self.onScreenNoticeContainerBottomConstraintConstant
                    self.view.layoutIfNeeded()
                })
            }
            .store(in: &notificationObservers)
    }

    /// Adjust the current Notice so it will always be in the correct y-position after the
    /// device is rotated.
    private func listenToOrientationChangeEvents() {
        NotificationCenter.default.publisher(for: .WPTabBarHeightChanged)
            .sink { [weak self] _ in
                guard let self = self,
                    let containerView = self.currentNoticePresentation?.containerView else {
                        return
                }

                containerView.bottomConstraint?.constant = -self.window.untouchableViewController.offsetOnscreen
            }
            .store(in: &notificationObservers)
    }

    /// Handle all changes in the `NoticeStore`.
    ///
    /// In here, we determine whether to show a Notice or dismiss the currently shown Notice based
    /// on the value of `NoticeStore.currentNotice`.
    private func onStoreChange() {
        guard currentNoticePresentation?.notice != store.currentNotice else {
            return
        }

        dismissForegroundNotice()

        currentNoticePresentation = nil

        guard let notice = store.currentNotice else {
            return
        }

        if let presentation = present(notice) {
            currentNoticePresentation = presentation
        } else {
            // We were not able to show the `notice` so we will dispatch a .clear action. This
            // should prevent us from getting in a stuck state where `NoticeStore` thinks its
            // `currentNotice` is still being presented.
            ActionDispatcher.dispatch(NoticeAction.clear(notice))
        }
    }

    // MARK: - Presentation

    /// Present the `notice` in the UI (foreground) or as a push notification (background).
    ///
    /// - Returns: A `NoticePresentation` if the `notice` was presented, otherwise `nil`.
    private func present(_ notice: Notice) -> NoticePresentation? {
        if UIApplication.shared.applicationState == .background {
            return presentNoticeInBackground(notice)
        } else {
            return presentNoticeInForeground(notice)
        }
    }

    private func presentNoticeInBackground(_ notice: Notice) -> NoticePresentation? {
        guard let notificationInfo = notice.notificationInfo else {
            return nil
        }

        let content = UNMutableNotificationContent(notice: notice)
        let request = UNNotificationRequest(identifier: notificationInfo.identifier,
                                            content: content,
                                            trigger: nil)

        UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
            DispatchQueue.main.async {
                ActionDispatcher.dispatch(NoticeAction.clear(notice))
            }
        })

        return NoticePresentation(notice: notice, containerView: nil)
    }

    private func presentNoticeInForeground(_ notice: Notice) -> NoticePresentation? {
        generator.prepare()

        let noticeView = NoticeView(notice: notice)
        noticeView.translatesAutoresizingMaskIntoConstraints = false

        let noticeContainerView = NoticeContainerView(noticeView: noticeView)
        addNoticeContainerToPresentingViewController(noticeContainerView)
        addBottomConstraintToNoticeContainer(noticeContainerView)
        addTopConstraintToNoticeContainer(noticeContainerView)

        // At regular width, the notice shouldn't be any wider than 1/2 the app's width
        noticeContainerView.noticeWidthConstraint = noticeView.widthAnchor.constraint(equalTo: noticeContainerView.widthAnchor, multiplier: 0.5)
        let isRegularWidth = noticeContainerView.traitCollection.containsTraits(in: UITraitCollection(horizontalSizeClass: .regular))
        noticeContainerView.noticeWidthConstraint?.isActive = isRegularWidth

        NSLayoutConstraint.activate([
            noticeContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noticeContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        let dismiss = {
            ActionDispatcher.dispatch(NoticeAction.clear(notice))
        }
        noticeView.dismissHandler = dismiss

        if let feedbackType = notice.feedbackType {
            generator.notificationOccurred(feedbackType)
        }

        window.isHidden = false

        // Mask must be initialized after the window is shown or the view.frame will be zero
        view.mask = MaskView(parent: view, untouchableViewController: self.window.untouchableViewController)

        let offScreenBottomOffset = offScreenNoticeContainerBottomOffset(for: noticeContainerView)
        let fromState = animator.state(for: noticeContainerView, in: view, withTransition: .offscreen,
                                          bottomOffset: offScreenBottomOffset)
        let toState = animator.state(for: noticeContainerView, in: view, withTransition: .onscreen,
                                        bottomOffset: onScreenNoticeContainerBottomConstraintConstant)
        animator.animatePresentation(fromState: fromState, toState: toState, completion: {
            // Quick Start notices don't get automatically dismissed
            guard notice.style.isDismissable else {
                return
            }

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Animations.dismissDelay, execute: dismiss)
        })

        UIAccessibility.post(notification: .layoutChanged, argument: noticeContainerView)

        return NoticePresentation(notice: notice, containerView: noticeContainerView)
    }

    private func addNoticeContainerToPresentingViewController(_ noticeContainer: UIView) {
        view.addSubview(noticeContainer)
    }

    private func addBottomConstraintToNoticeContainer(_ container: NoticeContainerView) {
        let constraint = container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        container.bottomConstraint = constraint
        constraint.isActive = false
    }

    private func addTopConstraintToNoticeContainer(_ container: NoticeContainerView) {
        let constraint = container.topAnchor.constraint(equalTo: view.bottomAnchor)
        container.topConstraint = constraint
        constraint.priority = UILayoutPriority.defaultHigh
        constraint.isActive = false
    }

    // MARK: - Dismissal

    public class func dismiss(container: NoticeContainerView) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .nanoseconds(1)) {
            UIView.animate(withDuration: Animations.appearanceDuration,
                           delay: 0,
                           usingSpringWithDamping: Animations.appearanceSpringDamping,
                           initialSpringVelocity: Animations.appearanceSpringVelocity,
                           options: [],
                           animations: {
                    container.noticeView.alpha = WPAlphaZero
            },
                           completion: { _ in
                    container.removeFromSuperview()
            })
        }
    }

    private func dismissForegroundNotice() {
        guard let container = currentNoticePresentation?.containerView,
            container.superview != nil else {
                return
        }
        let bottomOffset = offScreenNoticeContainerBottomOffset(for: container)
        let toState = animator.state(for: container, in: view, withTransition: .offscreen, bottomOffset: bottomOffset)
        animator.animatePresentation(fromState: {}, toState: toState, completion: { [weak self] in
            container.removeFromSuperview()

            // It is possible that when the dismiss animation finished, another Notice was already
            // being shown. Hiding the window would cause that new Notice to be invisible.
            if self?.currentNoticePresentation == nil {
                UIAccessibility.post(notification: .layoutChanged, argument: nil)

                self?.window.isHidden = true
            }
        })
    }

    // MARK: - Animations

    private var onScreenNoticeContainerBottomConstraintConstant: CGFloat {
        switch self.currentKeyboardPresentation {
        case .present(let keyboardHeight):
            return -keyboardHeight
        case .notPresent:
            return -window.untouchableViewController.offsetOnscreen
        }
    }

    private func offScreenNoticeContainerBottomOffset(for container: UIView) -> CGFloat {
        switch self.currentKeyboardPresentation {
        case .present(let keyboardHeight):
            return -keyboardHeight + container.bounds.height
        case .notPresent:
            return window.untouchableViewController.offsetOffscreen
        }
    }

    private enum Animations {
        static let appearanceDuration: TimeInterval = 1.0
        static let appearanceSpringDamping: CGFloat = 0.7
        static let appearanceSpringVelocity: CGFloat = 0.0
        static let dismissDelay: TimeInterval = 5.0
    }
}

private extension UIWindow {
    /// Returns a rectangle based on this window offset such that a new window created
    /// with this frame will not overtake the status bar responsibilities
    ///
    /// - Returns: CGRect based on this window's frame
    /// - Note: Turns out that a small alteration to the frame is enough to accomplish this.
    func offsetToAvoidStatusBar() -> CGRect {
        return self.frame.insetBy(dx: Offsets.minimalEdgeOffset, dy: Offsets.minimalEdgeOffset)
    }

    private enum Offsets {
        static let minimalEdgeOffset: CGFloat = 1.0
    }
}

/// Small wrapper view that ensures a notice remains centered and at a maximum
/// width when displayed in a regular size class.
///
class NoticeContainerView: UIView {
    /// The space between the Notice and its parent View
    private let containerMargin = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 15.0, right: 8.0)
    var bottomConstraint: NSLayoutConstraint?
    var topConstraint: NSLayoutConstraint?
    var noticeWidthConstraint: NSLayoutConstraint?

    let noticeView: NoticeView

    init(noticeView: NoticeView) {
        self.noticeView = noticeView

        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false

        layoutMargins = containerMargin

        // Padding views on either side, of equal width to ensure centering
        let leftPaddingView = UIView()
        let rightPaddingView = UIView()
        rightPaddingView.translatesAutoresizingMaskIntoConstraints = false
        leftPaddingView.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView(arrangedSubviews: [leftPaddingView, noticeView, rightPaddingView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 0

        let paddingWidthConstraint = leftPaddingView.widthAnchor.constraint(equalToConstant: 0)
        paddingWidthConstraint.priority = .lowButABigHigher

        addSubview(stackView)

        NSLayoutConstraint.activate([
            paddingWidthConstraint,
            leftPaddingView.widthAnchor.constraint(equalTo: rightPaddingView.widthAnchor),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
            ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        let isRegularWidth = traitCollection.containsTraits(in: UITraitCollection(horizontalSizeClass: .regular))
        noticeWidthConstraint?.isActive = isRegularWidth

        layoutIfNeeded()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return noticeView.point(inside: convert(point, to: noticeView), with: event)
    }
}

private extension NoticePresenter {
    /// A view that should be used as a mask for the `NoticePresenter.view`.
    ///
    /// The mask will prevent any `NoticeView` from animating on top of a tab bar.
    class MaskView: UIView {
        private unowned let parentView: UIView
        private unowned let untouchableVC: UntouchableViewController

        init(parent: UIView, untouchableViewController: UntouchableViewController) {
            // We use the parent's frame to determine the size of this `MaskView`. If a parent has
            // a zero frame, this may be that it is not visible. Check that the parent view's
            // window is not hidden.
            assert(parent.frame != .zero, "The parent view should have a non-zero frame. Is it visible?")

            self.parentView = parent
            self.untouchableVC = untouchableViewController

            super.init(frame: MaskView.calculateFrame(parent: parent, untouchableVC: untouchableViewController))

            isUserInteractionEnabled = false
            translatesAutoresizingMaskIntoConstraints = false
            backgroundColor = .blue

            let nc = NotificationCenter.default
            nc.addObserver(self, selector: #selector(updateFrame(notification:)),
                           name: UIDevice.orientationDidChangeNotification, object: nil)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc func updateFrame(notification: Notification) {
            // Update the `frame` on the next run loop. When this Notification event handler is
            // called, the `self.parentView` still has the frame from the previous orientation.
            // Running this routine after the current run loop ensures we have the correct frame.
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.frame = MaskView.calculateFrame(parent: self.parentView, untouchableVC: self.untouchableVC)
            }
        }

        private static func calculateFrame(parent: UIView,
                                           untouchableVC: UntouchableViewController) -> CGRect {
            return CGRect(
                x: 0,
                y: 0,
                width: parent.bounds.width,
                height: parent.bounds.height - untouchableVC.offsetOnscreen
            )
        }
    }
}

private extension UNMutableNotificationContent {
    convenience init(notice: Notice) {
        self.init()

        title = notice.notificationInfo?.title ?? notice.title

        if let body = notice.notificationInfo?.body {
            self.body = body
        } else if let message = notice.message {
            subtitle = message
        }

        if let categoryIdentifier = notice.notificationInfo?.categoryIdentifier {
            self.categoryIdentifier = categoryIdentifier
        }

        if let userInfo = notice.notificationInfo?.userInfo {
            self.userInfo = userInfo
        }

        sound = .default
    }
}

private extension UILayoutPriority {
    static let lowButABigHigher = UILayoutPriority.defaultLow + 10
}
