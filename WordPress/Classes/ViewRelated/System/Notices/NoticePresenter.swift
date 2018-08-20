import Foundation
import UIKit
import UserNotifications
import WordPressFlux

class NoticePresenter: NSObject {
    private let store: NoticeStore
    private let presentingViewController: UIViewController
    private var currentContainer: NoticeContainerView?

    let generator = UINotificationFeedbackGenerator()

    private var storeReceipt: Receipt?

    private init(store: NoticeStore, presentingViewController: UIViewController) {
        self.store = store
        self.presentingViewController = presentingViewController

        super.init()

        storeReceipt = store.onChange { [weak self] in
            self?.presentNextNoticeIfAvailable()
        }
    }

    @objc convenience init(presentingViewController: UIViewController) {
        self.init(store: StoreContainer.shared.notice, presentingViewController: presentingViewController)
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
        guard let view = presentingViewController.view else {
            return
        }

        generator.prepare()

        let noticeView = makeNoticeView(for: notice)
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
            if case .quickStart(_) = notice.style {
                return
            }

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Animations.dismissDelay, execute: dismiss)
        })
    }

    private func makeNoticeView(for notice: Notice) -> NoticeView {
        switch notice.style {
        case .quickStart:
            return QuickStartNoticeView(notice: notice)
        default:
            return NoticeView(notice: notice)
        }
    }

    private func offscreenState(for noticeContainer: NoticeContainerView) -> (() -> ()) {
        return { [weak self] in
            guard let strongSelf = self,
                let view = strongSelf.presentingViewController.view else {
                return
            }

            noticeContainer.noticeView.alpha = WPAlphaZero
            noticeContainer.bottomConstraint?.constant = strongSelf.offscreenBottomOffset

            view.layoutIfNeeded()
        }
    }

    private func onscreenState(for noticeContainer: NoticeContainerView)  -> (() -> ()) {
        return { [weak self] in
            guard let strongSelf = self,
                let view = strongSelf.presentingViewController.view else {
                    return
            }

            noticeContainer.noticeView.alpha = WPAlphaFull
            noticeContainer.bottomConstraint?.constant = 0

            view.layoutIfNeeded()
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
        self.animatePresentation(fromState: {}, toState: offscreenState(for: container), completion: {
            container.removeFromSuperview()
            self.dismiss()
        })
    }

    private func dismiss() {
        ActionDispatcher.dispatch(NoticeAction.dismiss)
    }

    private func addNoticeContainerToPresentingViewController(_ noticeContainer: UIView) {
        if let tabBarController = presentingViewController as? UITabBarController {
            tabBarController.view.insertSubview(noticeContainer, belowSubview: tabBarController.tabBar)
        } else {
            presentingViewController.view.addSubview(noticeContainer)
        }
    }

    private func addBottomConstraintToNoticeContainer(_ container: NoticeContainerView) {
        let constraint: NSLayoutConstraint
        if let tabBarController = presentingViewController as? UITabBarController {
            constraint = container.bottomAnchor.constraint(equalTo: tabBarController.tabBar.topAnchor)
        } else {
            // Force unwrapping, as the calling method has already guarded against a nil view
            constraint = container.bottomAnchor.constraint(equalTo: presentingViewController.view!.bottomAnchor)
        }
        container.bottomConstraint = constraint
        constraint.isActive = true
    }

    private var offscreenBottomOffset: CGFloat {
        if let tabBarController = presentingViewController as? UITabBarController {
            return tabBarController.tabBar.bounds.height
        } else {
            return 0
        }
    }

    typealias AnimationBlock = () -> Void

    private func animatePresentation(fromState: AnimationBlock, toState: @escaping AnimationBlock, completion: @escaping AnimationBlock) {
        fromState()

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

    private enum Animations {
        static let appearanceDuration: TimeInterval = 1.0
        static let appearanceSpringDamping: CGFloat = 0.7
        static let appearanceSpringVelocity: CGFloat = 0.0
        static let dismissDelay: TimeInterval = 5.0
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
        paddingWidthConstraint.priority = .defaultLow

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

        sound = .default()
    }
}
