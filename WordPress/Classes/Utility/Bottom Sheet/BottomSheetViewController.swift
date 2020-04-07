import UIKit

class BottomSheetViewController: UIViewController {
    enum Constants {
        static let gripHeight: CGFloat = 5
        static let cornerRadius: CGFloat = 8
        static let buttonSpacing: CGFloat = 8
        static let additionalSafeAreaInsetsRegular: UIEdgeInsets = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        static let minimumWidth: CGFloat = 300

        enum Header {
            static let spacing: CGFloat = 16
            static let insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        }

        enum Button {
            static let height: CGFloat = 54
            static let contentInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 35)
            static let titleInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
            static let imageTintColor: UIColor = .neutral(.shade30)
            static let font: UIFont = .preferredFont(forTextStyle: .callout)
            static let textColor: UIColor = .text
        }

        enum Stack {
            static let insets: UIEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        }
    }

    private weak var childViewController: DrawerPresentableViewController?

    init(childViewController: DrawerPresentableViewController) {
        self.childViewController = childViewController
        super.init(nibName: nil, bundle: nil)
    }

    func show(from presenting: UIViewController, sourceView: UIView? = nil) {
        if UIDevice.isPad() {
            modalPresentationStyle = .popover
            popoverPresentationController?.sourceView = sourceView ?? UIView()
            popoverPresentationController?.sourceRect = sourceView?.bounds ?? .zero
        } else {
            transitioningDelegate = self
            modalPresentationStyle = .custom
        }

        presenting.present(self, animated: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var gripButton: UIButton = {
        let button = GripButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        return button
    }()

    @objc func buttonPressed() {
        dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        view.clipsToBounds = true
        view.layer.cornerRadius = Constants.cornerRadius
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        view.backgroundColor = .basicBackground

        NSLayoutConstraint.activate([
            gripButton.heightAnchor.constraint(equalToConstant: Constants.gripHeight)
        ])

        guard let childViewController = childViewController else {
            return
        }

        addChild(childViewController)

        let stackView = UIStackView(arrangedSubviews: [
            gripButton,
            childViewController.view
        ])

        stackView.setCustomSpacing(Constants.Header.spacing, after: gripButton)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical

        refreshForTraits()

        view.addSubview(stackView)
        view.pinSubviewToSafeArea(stackView, insets: Constants.Stack.insets)

        childViewController.didMove(toParent: self)
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        refreshForTraits()
    }

    private func refreshForTraits() {
        if presentingViewController?.traitCollection.horizontalSizeClass == .regular && presentingViewController?.traitCollection.verticalSizeClass != .compact {
            gripButton.isHidden = true
            additionalSafeAreaInsets = Constants.additionalSafeAreaInsetsRegular
        } else {
            gripButton.isHidden = false
            additionalSafeAreaInsets = .zero
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        return preferredContentSize = CGSize(width: Constants.minimumWidth, height: view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height)
    }

    @objc func keyboardWillShow(_ notification: NSNotification) {
        self.presentedVC?.transition(to: .expanded)
    }

    @objc func keyboardWillHide(_ notification: NSNotification) {
        self.presentedVC?.transition(to: .collapsed)
    }
}

extension BottomSheetViewController: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BottomSheetAnimationController(transitionType: .presenting)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BottomSheetAnimationController(transitionType: .dismissing)
    }

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return DrawerPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

// MARK: - DrawerDelegate
extension BottomSheetViewController: DrawerPresentable {
    var compactWidth: DrawerWidth {
        childViewController?.compactWidth ?? .percentage(0.66)
    }

    var expandedHeight: DrawerHeight {
        return childViewController?.expandedHeight ?? .maxHeight
    }

    var collapsedHeight: DrawerHeight {
        return childViewController?.collapsedHeight ?? .contentHeight(200)
    }

    var scrollableView: UIScrollView? {
        return childViewController?.scrollableView
    }
}
