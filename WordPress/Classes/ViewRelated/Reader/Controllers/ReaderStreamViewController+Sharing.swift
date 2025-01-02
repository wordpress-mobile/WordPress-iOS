import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

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
        let button = UIBarButtonItem(title: nil, image: UIImage(systemName: "square.and.arrow.up"), target: self, action: #selector(shareButtonTapped))
        button.tag = NavigationItemTag.share.rawValue
        button.accessibilityLabel = SharedStrings.Button.share
        addRightBarButtonItem(button)
    }

    func addRightBarButtonItem(_ item: UIBarButtonItem, after afterTag: NavigationItemTag? = nil) {
        var items = self.navigationItem.rightBarButtonItems ?? []
        guard !items.contains(where: { $0.tag == item.tag }) else { return }
        if let afterTag, let index = items.firstIndex(where: { $0.tag == afterTag.rawValue }) {
            items.insert(item, at: index)
        } else {
            items.append(item)
        }
        self.navigationItem.rightBarButtonItems = items
    }

    // MARK: Private behavior

    private func removeShareButton() {
        navigationItem.rightBarButtonItem = nil
    }

    @objc private func shareButtonTapped(_ sender: UIBarButtonItem) {
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
            presentationController.sourceItem = sender
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

        guard let activityType else {
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

        return UTType.url.identifier
    }
}
