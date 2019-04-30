protocol NoResultsViewHost: class {
    typealias NoResultsCustomizationBlock = (NoResultsViewController) -> Void

    var noResultsViewController: NoResultsViewController { get }
}

extension NoResultsViewHost where Self: UIViewController {
    func configureAndDisplayNoResults(on view: UIView,
                                      title: String,
                                      subtitle: String? = nil,
                                      buttonTitle: String? = nil,
                                      accessoryView: UIView? = nil,
                                      animated: Bool = true,
                                      customizationBlock: NoResultsCustomizationBlock? = nil) {
        noResultsViewController.configure(title: title,
                                          buttonTitle: buttonTitle,
                                          subtitle: subtitle,
                                          accessoryView: accessoryView)
        displayNoResults(on: view,
                         animated: animated,
                         customizationBlock: customizationBlock)
    }

    func updateNoResults(title: String,
                         subtitle: String? = nil,
                         buttonTitle: String? = nil,
                         accessoryView: UIView? = nil) {
        noResultsViewController.configure(title: title,
                                          buttonTitle: buttonTitle,
                                          subtitle: subtitle,
                                          accessoryView: accessoryView)
        noResultsViewController.hideImageView(accessoryView == nil)
        noResultsViewController.updateView()
    }

    func hideNoResults(_ completion: (() -> Void)? = nil) {
        if noResultsViewController.view.superview == nil {
            return
        }

        noResultsViewController.removeFromView()
        completion?()
    }

    func displayNoResults(on view: UIView,
                          animated: Bool = true,
                          customizationBlock: NoResultsCustomizationBlock? = nil) {
        if noResultsViewController.view.superview != nil {
            return
        }

        noResultsViewController.view.frame = view.frame
        noResultsViewController.view.frame.origin.y = 0
        customizationBlock?(noResultsViewController)
        addChild(noResultsViewController)

        if animated {
            view.addSubview(withFadeAnimation: noResultsViewController.view)
        }
        noResultsViewController.didMove(toParent: self)
    }
}
