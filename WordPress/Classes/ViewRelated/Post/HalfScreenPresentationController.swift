import Foundation

// Should be added to WordpressUI?
class HalfScreenPresentationController: FancyAlertPresentationController {
    override var frameOfPresentedViewInContainerView: CGRect {
        let height = containerView?.bounds.height ?? 0
        let width = containerView?.bounds.width ?? 0
        return CGRect(x: 0, y: height/2, width: width, height: height/2)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if size.width > size.height {
            let height = containerView?.bounds.height ?? 0
            let width = containerView?.bounds.width ?? 0
            presentedView?.frame = CGRect(x: 0, y: 0, width: width, height: height)
        } else {
            let height = containerView?.bounds.height ?? 0
            let width = containerView?.bounds.width ?? 0
            presentedView?.frame = CGRect(x: 0, y: height/2, width: width, height: height/2)
        }
    }

    // This may need to be added to FancyAlertPresentationController
    override var shouldPresentInFullscreen: Bool {
        return false
    }
}
