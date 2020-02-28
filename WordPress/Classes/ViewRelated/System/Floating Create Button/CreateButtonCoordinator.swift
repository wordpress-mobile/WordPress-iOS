import Gridicons

@objc class CreateButtonCoordinator: NSObject {

    private enum Constants {
        static let padding: CGFloat = -16
        static let heightWidth: CGFloat = 56
        static let popoverOffset: CGFloat = -10
    }

    var button: FloatingActionButton = {
        let button = FloatingActionButton(image: Gridicon.iconOfType(.create))
        button.accessibilityLabel = NSLocalizedString("Create", comment: "Accessibility label for create floating action button")
        button.accessibilityIdentifier = "floatingCreateButton"
        button.accessibilityHint = NSLocalizedString("Creates new post or page", comment: " Accessibility hint for create floating action button")
        return button
    }()

    private weak var viewController: UIViewController?

    let newPost: () -> Void
    let newPage: () -> Void

    @objc init(_ viewController: UIViewController, newPost: @escaping () -> Void, newPage: @escaping () -> Void) {
        self.viewController = viewController
        self.newPost = newPost
        self.newPage = newPage
    }

    /// Should be called any time the `viewController`'s trait collections change
    /// - Parameter previousTraitCollect: The previous trait collection
    @objc func presentingTraitCollectionDidChange(_ previousTraitCollection: UITraitCollection, newTraitCollection: UITraitCollection) {
        if viewController?.presentedViewController is ActionSheetViewController && previousTraitCollection.verticalSizeClass == newTraitCollection.verticalSizeClass {
            viewController?.dismiss(animated: true, completion: { [weak self] in
                self?.showCreateSheet()
            })
        }
    }

    @objc func add(to view: UIView, trailingAnchor: NSLayoutXAxisAnchor, bottomAnchor: NSLayoutYAxisAnchor) {
        button.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(button)

        /// A trailing constraint that is activated in `updateConstraints` at a later time when everything should be set up
        let trailingConstraint = button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: Constants.padding)
        button.trailingConstraint = trailingConstraint

        NSLayoutConstraint.activate([
            button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Constants.padding),
            button.heightAnchor.constraint(equalToConstant: Constants.heightWidth),
            button.widthAnchor.constraint(equalToConstant: Constants.heightWidth)
        ])

        button.addTarget(self, action: #selector(showCreateSheet), for: .touchUpInside)
    }

    @objc private func showCreateSheet() {
        let actionSheetVC = actionSheetController()
        viewController?.present(actionSheetVC, animated: true, completion: nil)
    }

    private func actionSheetController() -> UIViewController {

        let postsButton = ActionSheetButton(title: NSLocalizedString("Blog post", comment: "Create new Blog Post button title"), image: Gridicon.iconOfType(.posts), target: self, selector: #selector(showNewPost))

        let pagesButton = ActionSheetButton(title: NSLocalizedString("Site page", comment: "Create new Site Page button title"), image: Gridicon.iconOfType(.pages), target: self, selector: #selector(showNewPage))

        let actionSheetController = ActionSheetViewController(headerTitle: NSLocalizedString("Create New", comment: "Create New header text"), buttons: [postsButton, pagesButton])

        if viewController?.traitCollection.horizontalSizeClass == .regular && viewController?.traitCollection.verticalSizeClass == .regular {
            actionSheetController.modalPresentationStyle = .popover
        } else {
            actionSheetController.modalPresentationStyle = .custom
        }

        actionSheetController.popoverPresentationController?.sourceView = button
        actionSheetController.popoverPresentationController?.sourceRect = button.bounds.offsetBy(dx: 0, dy: Constants.popoverOffset)
        actionSheetController.transitioningDelegate = self

        return actionSheetController
    }

    @objc func hideCreateButton() {
        button.springAnimation(toShow: false)
    }

    @objc func showCreateButton() {
        button.setNeedsUpdateConstraints() // See `FloatingActionButton` implementation for more info on why this is needed.
        button.springAnimation(toShow: true)
    }

    @objc func showNewPost() {
        newPost()
    }

    @objc func showNewPage() {
        newPage()
    }
}

// MARK: Tranisitioning Delegate

extension CreateButtonCoordinator: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PullDownAnimationController(transitionType: .presenting)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PullDownAnimationController(transitionType: .dismissing)
    }

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentationController = BottomSheetPresentationController(presentedViewController: presented, presenting: presenting)
        return presentationController
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return (viewController?.presentedViewController?.presentationController as? BottomSheetPresentationController)?.interactionController
    }
}
