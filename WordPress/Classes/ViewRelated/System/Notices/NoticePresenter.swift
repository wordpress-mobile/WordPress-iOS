import Foundation
import UIKit
import WordPressFlux

class NoticePresenter: NSObject {
    private let store: NoticeStore
    private let presentingViewController: UIViewController

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
        guard let view = presentingViewController.view else {
            return
        }

        let noticeView = NoticeView(notice: notice)
        noticeView.translatesAutoresizingMaskIntoConstraints = false

        addNoticeViewToPresentingViewController(noticeView)

        let bottomConstraint = noticeView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        NSLayoutConstraint.activate([
            noticeView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            noticeView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            bottomConstraint
        ])

        let fromState = {
            noticeView.alpha = WPAlphaZero
            bottomConstraint.constant = 0

            view.layoutIfNeeded()
        }

        let toState = {
            noticeView.alpha = WPAlphaFull
            bottomConstraint.constant = -self.presentingViewBottomMargin

            view.layoutIfNeeded()
        }

        let dismiss = {
            guard noticeView.superview != nil else {
                return
            }

            self.animatePresentation(fromState: {}, toState: fromState, completion: {
                self.dismiss()
            })
        }

        noticeView.dismissHandler = dismiss

        animatePresentation(fromState: fromState, toState: toState, completion: {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Animations.dismissDelay, execute: dismiss)
        })
    }

    private func dismiss() {
        ActionDispatcher.dispatch(NoticeAction.dismiss)
    }

    private func addNoticeViewToPresentingViewController(_ noticeView: NoticeView) {
        if let tabBarController = presentingViewController as? UITabBarController {
            tabBarController.view.insertSubview(noticeView, belowSubview: tabBarController.tabBar)
        } else {
            presentingViewController.view.addSubview(noticeView)
        }
    }

    private var presentingViewBottomMargin: CGFloat {
        let bottomMargin: CGFloat = 16.0

        if let tabBarController = presentingViewController as? UITabBarController {
            return bottomMargin + tabBarController.tabBar.bounds.height
        } else {
            return bottomMargin
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
        static let dismissDelay: TimeInterval = 3.0
    }
}
