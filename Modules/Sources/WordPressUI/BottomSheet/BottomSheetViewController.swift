import UIKit

public class BottomSheetViewController: UIViewController {
    public enum Constants {
        static let gripHeight: CGFloat = 5
        static let cornerRadius: CGFloat = 8
        static let buttonSpacing: CGFloat = 8
        static let minimumWidth: CGFloat = 300

        /// The height of the space above the bottom sheet content, including the grip view and space around it.
        ///
        public static let additionalContentTopMargin: CGFloat = BottomSheetViewController.Constants.gripHeight
            + BottomSheetViewController.Constants.Header.spacing
            + BottomSheetViewController.Constants.Stack.insets.top

        enum Header {
            static let spacing: CGFloat = 16
            static let insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        }

        enum Button {
            static let height: CGFloat = 54
            static let contentInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 35)
            static let titleInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        }

        enum Stack {
            static let insets: UIEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        }
    }

    private var customHeaderSpacing: CGFloat?

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return childViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }

    /// Additional safe are insets for regular horizontal size class
    public var additionalSafeAreaInsetsRegular: UIEdgeInsets = .zero

    private weak var childViewController: DrawerPresentableViewController?

    public init(childViewController: DrawerPresentableViewController,
         customHeaderSpacing: CGFloat? = nil) {
        self.childViewController = childViewController
        self.customHeaderSpacing = customHeaderSpacing
        super.init(nibName: nil, bundle: nil)
    }

    /// Presents the bottom sheet given an optional anchor and arrow directions for the popover on iPad.
    /// If no anchors are provided, on iPad it will present a form sheet.
    /// - Parameters:
    ///   - presenting: the view controller that presents the bottom sheet.
    ///   - sourceView: optional anchor view for the popover on iPad.
    ///   - sourceBarButtonItem: optional anchor bar button item for the popover on iPad. If non-nil, `sourceView` and `arrowDirections` are not used.
    ///   - arrowDirections: optional arrow directions for the popover on iPad.
    public func show(from presenting: UIViewController,
                     sourceView: UIView? = nil,
                     sourceBarButtonItem: UIBarButtonItem? = nil,
                     arrowDirections: UIPopoverArrowDirection = .any) {
        if UIDevice.isPad() {

            // If the anchor views are not set, or the user is using a larger text option
            // we'll display the content in a sheet
            if (sourceBarButtonItem == nil && sourceView == nil) ||
                traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
                modalPresentationStyle = .formSheet
            } else {
                modalPresentationStyle = .popover

                if let sourceBarButtonItem = sourceBarButtonItem {
                    popoverPresentationController?.barButtonItem = sourceBarButtonItem
                } else {
                    popoverPresentationController?.permittedArrowDirections = arrowDirections
                    popoverPresentationController?.sourceView = sourceView
                    popoverPresentationController?.sourceRect = sourceView?.bounds ?? .zero
                }

                popoverPresentationController?.delegate = self
                popoverPresentationController?.backgroundColor = view.backgroundColor
            }

        } else {
            transitioningDelegate = self
            modalPresentationStyle = .custom
        }
        presenting.present(self, animated: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var gripButton: UIButton = {
        let button = GripButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(
            self,
            action: #selector(buttonPressed),
            for: .touchUpInside
        )
        button.accessibilityLabel = NSLocalizedString("Dismiss", comment: "Accessibility label for button to dismiss a bottom sheet")
        return button
    }()

    private var stackView: UIStackView!

    private var defaultBrackgroundColor: UIColor {
        if #available(iOS 13, *) {
            return .systemBackground
        }
        return .white
    }

    @objc func buttonPressed() {
        dismiss(animated: true, completion: nil)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        view.clipsToBounds = true
        view.layer.cornerRadius = Constants.cornerRadius
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        view.backgroundColor = childViewController?.view.backgroundColor ?? defaultBrackgroundColor

        NSLayoutConstraint.activate([
            gripButton.heightAnchor.constraint(equalToConstant: Constants.gripHeight)
        ])

        guard let childViewController = childViewController else {
            return
        }

        addChild(childViewController)

        stackView = UIStackView(arrangedSubviews: [
            gripButton,
            childViewController.view
        ])

        stackView.setCustomSpacing(customHeaderSpacing ?? Constants.Header.spacing, after: gripButton)

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

    override public var preferredContentSize: CGSize {
        set {
            childViewController?.view.layoutIfNeeded()

            childViewController?.preferredContentSize = newValue
            // Continue to make the assignment via super so preferredContentSizeDidChange is called on iPad popovers, resizing them as needed.
            super.preferredContentSize = computePreferredContentSize()
        }
        get {
            return computePreferredContentSize()
        }
    }

    func computePreferredContentSize() -> CGSize {
        return (childViewController?.preferredContentSize ?? super.preferredContentSize)
    }

    public override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        // Update our preferred size in response to a child updating theres.
        // While this leads to a recursive call, the sizes are the same preventing a loop.
        // The assignment is needed in order for iPad popovers to correctly resize.
        preferredContentSize = container.preferredContentSize
    }

    override public func accessibilityPerformEscape() -> Bool {
        dismiss(animated: true, completion: nil)
        return true
    }

    private func refreshForTraits() {
        if presentingViewController?.traitCollection.horizontalSizeClass == .regular && presentingViewController?.traitCollection.verticalSizeClass != .compact {
            gripButton.isHidden = true
            additionalSafeAreaInsets = additionalSafeAreaInsetsRegular
        } else {
            gripButton.isHidden = false
            additionalSafeAreaInsets = .zero
        }
    }

    @objc func keyboardWillShow(_ notification: NSNotification) {
        guard childViewController?.presentedViewController == nil else {
            return
        }

        self.presentedVC?.transition(to: .expanded)
    }

    @objc func keyboardWillHide(_ notification: NSNotification) {
        guard childViewController?.presentedViewController == nil else {
            return
        }

        self.presentedVC?.transition(to: .collapsed)
    }
}

extension BottomSheetViewController: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BottomSheetAnimationController(transitionType: .presenting)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        handleDismiss()

        return BottomSheetAnimationController(transitionType: .dismissing)
    }

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return DrawerPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

// MARK: - DrawerDelegate
extension BottomSheetViewController: DrawerPresentable {
    public var allowsUserTransition: Bool {
        return childViewController?.allowsUserTransition ?? true
    }

    public var allowsTapToDismiss: Bool {
        childViewController?.allowsTapToDismiss ?? true
    }

    public var allowsDragToDismiss: Bool {
        childViewController?.allowsDragToDismiss ?? true
    }

    public var compactWidth: DrawerWidth {
        childViewController?.compactWidth ?? .percentage(0.66)
    }

    public var expandedHeight: DrawerHeight {
        return childViewController?.expandedHeight ?? .maxHeight
    }

    public var collapsedHeight: DrawerHeight {
        return childViewController?.collapsedHeight ?? .contentHeight(200)
    }

    public var scrollableView: UIScrollView? {
        return childViewController?.scrollableView
    }

    public func handleDismiss() {
        if let childViewController = childViewController {
            childViewController.handleDismiss()
        }
    }
}

extension BottomSheetViewController: UIPopoverPresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        handleDismiss()
    }
}
