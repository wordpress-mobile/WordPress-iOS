protocol NoResultsViewDisplayable: class {
    var noResultsViewController: NoResultsViewController { get }
}

extension NoResultsViewDisplayable where Self: UIViewController {
    func configureAndDisplayNoResults(on view: UIView,
                                      title: String,
                                      subtitle: String? = nil,
                                      buttonTitle: String? = nil,
                                      accessoryView: UIView? = nil) {
        noResultsViewController.configure(title: title,
                                          buttonTitle: buttonTitle,
                                          subtitle: subtitle,
                                          accessoryView: accessoryView)
        displayNoResults(on: view)
    }

    func hideNoResults(_ completion: (() -> Void)? = nil) {
        if noResultsViewController.view.superview == nil {
            return
        }

        noResultsViewController.removeFromView()
        completion?()
    }

    func displayNoResults(on view: UIView) {
        if noResultsViewController.view.superview != nil {
            return
        }

        addChild(noResultsViewController)
        noResultsViewController.view.frame = view.frame
        noResultsViewController.view.frame.origin.y = 0

        view.addSubview(withFadeAnimation: noResultsViewController.view)
        noResultsViewController.didMove(toParent: self)
    }
}
