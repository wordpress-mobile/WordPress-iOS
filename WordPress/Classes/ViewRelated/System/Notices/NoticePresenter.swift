import Foundation
import UIKit
import UserNotifications
import WordPressFlux

class NoticePresenter: NSObject {
    private let store: NoticeStore
    private let window: UntouchableWindow
    private var view: UIView {
        guard let view = window.rootViewController?.view else {
            fatalError("Root view controller shouldn't be nil")
        }
        return view
    }
    private var currentContainer: NoticeContainerView?

    let generator = UINotificationFeedbackGenerator()

    private var storeReceipt: Receipt?

    private init(store: NoticeStore) {
        self.store = store

        let windowFrame: CGRect
        if let mainWindow = UIApplication.shared.keyWindow {
            windowFrame = mainWindow.offsetToAvoidStatusBar()
        } else {
            windowFrame = .zero
        }
        window = UntouchableWindow(frame: windowFrame)

        // this window level may affect some UI elements like share sheets.
        // however, since the alerts aren't permanently on screen, this isn't
        // often a problem.
        window.windowLevel = .alert
        window.isHidden = false

        super.init()

        storeReceipt = store.onChange { [weak self] in
            self?.presentNextNoticeIfAvailable()
        }
    }

    override convenience init() {
        self.init(store: StoreContainer.shared.notice)
    }

    private func presentNextNoticeIfAvailable() {
        if let notice = store.nextNotice {
            present(notice)
        }
    }

    private func present(_ notice: Notice) {
        if UIApplication.shared.applicationState == .background {
            presentNoticeInBackground(notice)
        } else {
            presentNoticeInForeground(notice)
        }
    }

    private func presentNoticeInBackground(_ notice: Notice) {
        guard let notificationInfo = notice.notificationInfo else {
            return
        }

        let content = UNMutableNotificationContent(notice: notice)
        let request = UNNotificationRequest(identifier: notificationInfo.identifier,
                                            content: content,
                                            trigger: nil)

        UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
            DispatchQueue.main.async {
                self.dismiss()
            }
        })
    }

    private func presentNoticeInForeground(_ notice: Notice) {
        generator.prepare()

        let noticeView = NoticeView(notice: notice)
        noticeView.translatesAutoresizingMaskIntoConstraints = false

        let noticeContainerView = NoticeContainerView(noticeView: noticeView)
        addNoticeContainerToPresentingViewController(noticeContainerView)
        currentContainer = noticeContainerView

        addBottomConstraintToNoticeContainer(noticeContainerView)

        NSLayoutConstraint.activate([
            noticeContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noticeContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        let fromState = offscreenState(for: noticeContainerView)

        let toState = onscreenState(for: noticeContainerView)

        let dismiss = {
            self.dismiss(container: noticeContainerView)
        }

        noticeView.dismissHandler = dismiss

        if let feedbackType = notice.feedbackType {
            generator.notificationOccurred(feedbackType)
        }

        animatePresentation(fromState: fromState, toState: toState, completion: {
            // Quick Start notices don't get automatically dismissed
            guard notice.style.isDismissable else {
                return
            }

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Animations.dismissDelay, execute: dismiss)
        })
    }

    private func offscreenState(for noticeContainer: NoticeContainerView) -> (() -> ()) {
        return { [weak self] in
            guard let self = self else {
                return
            }

            noticeContainer.noticeView.alpha = WPAlphaZero
            noticeContainer.bottomConstraint?.constant = self.window.untouchableViewController.offsetOffscreen

            self.view.layoutIfNeeded()
        }
    }

    private func onscreenState(for noticeContainer: NoticeContainerView)  -> (() -> ()) {
        return { [weak self] in
            guard let self = self else {
                return
            }

            noticeContainer.noticeView.alpha = WPAlphaFull
            noticeContainer.bottomConstraint?.constant = -self.window.untouchableViewController.offsetOnscreen

            self.window.isHidden = false

            self.view.layoutIfNeeded()
        }
    }

    public func dismissCurrentNotice() {
        guard let container = currentContainer else {
            return
        }

        dismiss(container: container)
    }

    private func dismiss(container: NoticeContainerView) {
        guard container.superview != nil else {
            return
        }

        currentContainer = nil
        self.animatePresentation(fromState: {}, toState: offscreenState(for: container), completion: { [weak self] in
            container.removeFromSuperview()
            self?.window.isHidden = true
            self?.dismiss()
        })
    }

    private func dismiss() {
        ActionDispatcher.dispatch(NoticeAction.dismiss)
    }

    private func addNoticeContainerToPresentingViewController(_ noticeContainer: UIView) {
        view.addSubview(noticeContainer)
    }

    private func addBottomConstraintToNoticeContainer(_ container: NoticeContainerView) {
        let constraint = container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        container.bottomConstraint = constraint
        constraint.isActive = true
    }

    typealias AnimationBlock = () -> Void

    private func animatePresentation(fromState: AnimationBlock, toState: @escaping AnimationBlock, completion: @escaping AnimationBlock) {
        fromState()

        // this delay avoids affecting other transitions like navigation pushes
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .nanoseconds(1)) {
            UIView.animate(withDuration: Animations.appearanceDuration,
                           delay: 0,
                           usingSpringWithDamping: Animations.appearanceSpringDamping,
                           initialSpringVelocity: Animations.appearanceSpringVelocity,
                           options: [],
                           animations: toState,
                           completion: { _ in
                            completion()
            })
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
private class NoticeContainerView: UIView {
    let containerMargin: CGFloat = 16.0
    var bottomConstraint: NSLayoutConstraint?

    let noticeView: UIView

    init(noticeView: UIView) {
        self.noticeView = noticeView

        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false

        layoutMargins = UIEdgeInsets(top: containerMargin,
                                     left: containerMargin,
                                     bottom: containerMargin,
                                     right: containerMargin)

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

    lazy var noticeWidthConstraint: NSLayoutConstraint = {
        // At regular width, the notice shouldn't be any wider than 1/2 the app's width
        return noticeView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5)
    }()

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        let isRegularWidth = traitCollection.containsTraits(in: UITraitCollection(horizontalSizeClass: .regular))
        noticeWidthConstraint.isActive = isRegularWidth

        layoutIfNeeded()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return noticeView.point(inside: convert(point, to: noticeView), with: event)
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
