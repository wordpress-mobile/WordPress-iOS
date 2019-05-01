protocol NoResultsViewHost: class {
    typealias NoResultsCustomizationBlock = (NoResultsViewController) -> Void
    typealias NoResultsAttributedSubtitleConfiguration = NoResultsViewController.AttributedSubtitleConfiguration

    var noResultsViewController: NoResultsViewController { get }
}

extension NoResultsViewHost where Self: UIViewController {

    /// Configure and display the no results view controller
    ///
    /// - Parameters:
    ///   - view: The no results view parentView. Required.
    ///   - title: Main descriptive text. Required.
    ///   - subtitle: Secondary descriptive text. Optional.
    ///   - buttonTitle: Title of action button. Optional.
    ///   - attributedSubtitle: Secondary descriptive attributed text. Optional.
    ///   - attributedSubtitleConfiguration: Called after default styling, for subtitle attributed text customization.
    ///   - image:              Name of image file to use. Optional.
    ///   - subtitleImage:      Name of image file to use in place of subtitle. Optional.
    ///   - accessoryView:      View to show instead of the image. Optional.
    ///   - animated: Enable the fade in transition. True by default.
    ///   - customizationBlock: Used to customize the view controller before being added. Optional.
    func configureAndDisplayNoResults(on view: UIView,
                                      title: String,
                                      subtitle: String? = nil,
                                      buttonTitle: String? = nil,
                                      attributedSubtitle: NSAttributedString? = nil,
                                      attributedSubtitleConfiguration: NoResultsAttributedSubtitleConfiguration? = nil,
                                      image: String? = nil,
                                      subtitleImage: String? = nil,
                                      accessoryView: UIView? = nil,
                                      animated: Bool = true,
                                      customizationBlock: NoResultsCustomizationBlock? = nil) {
        noResultsViewController.configure(title: title,
                                          buttonTitle: buttonTitle,
                                          subtitle: subtitle,
                                          attributedSubtitle: attributedSubtitle,
                                          attributedSubtitleConfiguration: attributedSubtitleConfiguration,
                                          image: image,
                                          subtitleImage: subtitleImage,
                                          accessoryView: accessoryView)
        displayNoResults(on: view,
                         animated: animated,
                         customizationBlock: customizationBlock)
    }

    /// Used to update the no results view controller
    ///
    /// - Parameters:
    ///   - view: The no results view parentView. Required.
    ///   - title: Main descriptive text. Required.
    ///   - subtitle: Secondary descriptive text. Optional.
    ///   - buttonTitle: Title of action button. Optional.
    ///   - attributedSubtitle: Secondary descriptive attributed text. Optional.
    ///   - attributedSubtitleConfiguration: Called after default styling, for subtitle attributed text customization.
    ///   - image:              Name of image file to use. Optional.
    ///   - subtitleImage:      Name of image file to use in place of subtitle. Optional.
    ///   - accessoryView:      View to show instead of the image. Optional.
    func updateNoResults(title: String,
                         subtitle: String? = nil,
                         buttonTitle: String? = nil,
                         attributedSubtitle: NSAttributedString? = nil,
                         attributedSubtitleConfiguration: NoResultsAttributedSubtitleConfiguration? = nil,
                         image: String? = nil,
                         subtitleImage: String? = nil,
                         accessoryView: UIView? = nil) {
        noResultsViewController.configure(title: title,
                                          buttonTitle: buttonTitle,
                                          subtitle: subtitle,
                                          attributedSubtitle: attributedSubtitle,
                                          attributedSubtitleConfiguration: attributedSubtitleConfiguration,
                                          image: image,
                                          subtitleImage: subtitleImage,
                                          accessoryView: accessoryView)
        noResultsViewController.hideImageView(accessoryView == nil)
        noResultsViewController.updateView()
    }

    /// Hide and remove the no results view controller
    ///
    /// - Parameter completion: Block called as soon the view controller has been removed.
    func hideNoResults(_ completion: (() -> Void)? = nil) {
        noResultsViewController.removeFromView()
        completion?()
    }

    /// Display the no result view controller
    ///
    /// - Parameters:
    ///   - view: The no results view parentView. Required.
    ///   - animated: Enable the fade in transition. True by default.
    ///   - customizationBlock: Used to customize the view controller before being added. Optional.
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
