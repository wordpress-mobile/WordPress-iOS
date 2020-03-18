
import MobileCoreServices

import Gridicons

// MARK: - Functionality related to sharing a blog via the reader.

extension ReaderStreamViewController {

    // MARK: Internal behavior

    /// Exposes the Share button if the currently selected Reader topic represents a site.
    ///
    func configureShareButtonIfNeeded() {
        guard let _ = readerTopic as? ReaderSiteTopic else {
            removeShareButton()
            return
        }

        let image = UIImage.gridicon(.shareiOS).withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        let button = CustomHighlightButton(frame: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(shareButtonTapped(_:)), for: .touchUpInside)

        let shareButton = UIBarButtonItem(customView: button)
        shareButton.accessibilityLabel = NSLocalizedString("Share", comment: "Spoken accessibility label")
        WPStyleGuide.setRightBarButtonItemWithCorrectSpacing(shareButton, for: navigationItem)
    }

    // MARK: Private behavior

    private func removeShareButton() {
        navigationItem.rightBarButtonItem = nil
    }

    @objc private func shareButtonTapped(_ sender: UIButton) {
        guard let sitePendingPost = readerTopic as? ReaderSiteTopic else {
            return
        }

        WPAppAnalytics.track(.readerSiteShared, withBlogID: sitePendingPost.siteID)

        let activities = WPActivityDefaults.defaultActivities() as! [UIActivity]
        let activityViewController = UIActivityViewController(activityItems: [sitePendingPost], applicationActivities: activities)
        activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            if completed {
                WPActivityDefaults.trackActivityType((activityType).map { $0.rawValue })
            }
        }

        if UIDevice.isPad() {
            activityViewController.modalPresentationStyle = .popover
        }

        if let presentationController = activityViewController.popoverPresentationController {
            presentationController.permittedArrowDirections = .any
            presentationController.sourceView = sender
            presentationController.sourceRect = sender.bounds
        }

        present(activityViewController, animated: true)
    }
}

// MARK: - ReaderSiteTopic support for sharing

private extension ReaderSiteTopic {
    var shareablePostData: Data {
        let shareSitePost = SharePost(title: title, summary: siteDescription, url: siteURL)
        return shareSitePost.data
    }

    var shareableURL: URL? {
        return URL(string: siteURL)
    }
}

extension ReaderSiteTopic: UIActivityItemSource {
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return shareableURL as Any
    }

    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {

        guard let activityType = activityType else {
            return nil
        }

        let value: Any?
        switch activityType {
        case SharePost.activityType:
            return shareablePostData
        default:
            value = shareableURL
        }

        return value
    }

    public func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {

        let value: String
        if activityType == nil {
            value = ""
        } else {
            value = title
        }

        return value
    }

    public func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {

        if activityType == SharePost.activityType {
            return ShareBlog.typeIdentifier
        }

        return kUTTypeURL as String
    }
}
