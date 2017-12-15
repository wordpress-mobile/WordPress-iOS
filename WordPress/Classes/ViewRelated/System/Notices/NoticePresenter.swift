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

        let noticeContainerView = NoticeContainerView(noticeView: noticeView)
        addNoticeContainerToPresentingViewController(noticeContainerView)

        let bottomConstraint = makeBottomConstraintForNoticeContainer(noticeContainerView)

        NSLayoutConstraint.activate([
            noticeContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noticeContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomConstraint
        ])

        let fromState = {
            noticeView.alpha = WPAlphaZero
            bottomConstraint.constant = self.offscreenBottomOffset

            view.layoutIfNeeded()
        }

        let toState = {
            noticeView.alpha = WPAlphaFull
            bottomConstraint.constant = 0

            view.layoutIfNeeded()
        }

        let dismiss = {
            guard noticeContainerView.superview != nil else {
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

    private func addNoticeContainerToPresentingViewController(_ noticeContainer: UIView) {
        if let tabBarController = presentingViewController as? UITabBarController {
            tabBarController.view.insertSubview(noticeContainer, belowSubview: tabBarController.tabBar)
        } else {
            presentingViewController.view.addSubview(noticeContainer)
        }
    }

    private func makeBottomConstraintForNoticeContainer(_ container: UIView) -> NSLayoutConstraint {
        if let tabBarController = presentingViewController as? UITabBarController {
            return container.bottomAnchor.constraint(equalTo: tabBarController.tabBar.topAnchor)
        }

        // Force unwrapping, as the calling method has already guarded against a nil view
        return container.bottomAnchor.constraint(equalTo: presentingViewController.view!.bottomAnchor)
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

    let noticeView: NoticeView

    init(noticeView: NoticeView) {
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
