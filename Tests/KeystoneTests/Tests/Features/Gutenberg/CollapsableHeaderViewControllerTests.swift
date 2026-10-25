import Testing
import UIKit

@testable import WordPress

@MainActor
@Suite("CollapsableHeaderViewController")
struct CollapsableHeaderViewControllerTests {
    @Test("resizing the window across size classes keeps the scroll position")
    func resizeAcrossSizeClassesKeepsScrollPosition() {
        let tableView = UITableView(frame: .zero, style: .plain)
        let dataSource = RowsDataSource()
        tableView.dataSource = dataSource
        tableView.rowHeight = 100
        let viewController = ResettingHeaderViewController(
            scrollableView: tableView,
            mainTitle: "Title",
            primaryActionTitle: "Done"
        )
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 800, height: 1000))
        window.traitOverrides.horizontalSizeClass = .regular
        window.rootViewController = viewController
        window.isHidden = false
        window.layoutIfNeeded()

        // Scrolled well past the header, which collapses.
        tableView.contentOffset.y = 1_000
        window.layoutIfNeeded()

        // A window resize: the size transition finishes, then the size class changes.
        viewController.viewWillTransition(to: CGSize(width: 600, height: 1000), with: FinishedTransitionCoordinator())
        window.traitOverrides.horizontalSizeClass = .compact
        window.updateTraitsIfNeeded()
        window.layoutIfNeeded()

        #expect(tableView.contentOffset.y == 1_000)
        withExtendedLifetime((window, dataSource)) {}
    }
}

/// Resets its header after every size transition, like the Site Creation design list.
private final class ResettingHeaderViewController: CollapsableHeaderViewController {
    override var alwaysResetHeaderOnRotation: Bool {
        true
    }
}

private final class RowsDataSource: NSObject, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        30
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        UITableViewCell()
    }
}

/// A transition coordinator for a transition that has already finished: it runs the animation and completion
/// blocks straight away.
private final class FinishedTransitionCoordinator: NSObject, UIViewControllerTransitionCoordinator {
    func animate(
        alongsideTransition animation: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?,
        completion: ((any UIViewControllerTransitionCoordinatorContext) -> Void)? = nil
    ) -> Bool {
        animation?(self)
        completion?(self)
        return true
    }

    func animateAlongsideTransition(
        in view: UIView?,
        animation: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?,
        completion: ((any UIViewControllerTransitionCoordinatorContext) -> Void)? = nil
    ) -> Bool {
        animate(alongsideTransition: animation, completion: completion)
    }

    func notifyWhenInteractionEnds(_ handler: @escaping (any UIViewControllerTransitionCoordinatorContext) -> Void) {}

    func notifyWhenInteractionChanges(_ handler: @escaping (any UIViewControllerTransitionCoordinatorContext) -> Void) {
    }

    var isAnimated: Bool { false }
    var presentationStyle: UIModalPresentationStyle { .none }
    var initiallyInteractive: Bool { false }
    var isInterruptible: Bool { false }
    var isInteractive: Bool { false }
    var isCancelled: Bool { false }
    var transitionDuration: TimeInterval { 0 }
    var percentComplete: CGFloat { 1 }
    var completionVelocity: CGFloat { 1 }
    var completionCurve: UIView.AnimationCurve { .linear }
    var containerView: UIView { UIView() }
    var targetTransform: CGAffineTransform { .identity }

    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        nil
    }

    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        nil
    }
}
