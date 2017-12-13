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
        noticeView.alpha = WPAlphaZero

        addNoticeViewToPresentingViewController(noticeView)

        let bottomConstraint = noticeView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        NSLayoutConstraint.activate([
            noticeView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            noticeView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            bottomConstraint
        ])
        view.layoutIfNeeded()

        UIView.animate(withDuration: Animations.appearanceDuration,
                       delay: 0,
                       usingSpringWithDamping: Animations.appearanceSpringDamping,
                       initialSpringVelocity: Animations.appearanceSpringVelocity,
                       options: [],
                       animations: {
            noticeView.alpha = WPAlphaFull
            bottomConstraint.constant = -self.presentingViewBottomMargin

            view.layoutIfNeeded()
        }, completion: nil)
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

    private func dismiss() {
        ActionDispatcher.dispatch(NoticeAction.dismiss)
    }

    private enum Animations {
        static let appearanceDuration: TimeInterval = 1.0
        static let appearanceSpringDamping: CGFloat = 0.7
        static let appearanceSpringVelocity: CGFloat = 0.0
    }
}
