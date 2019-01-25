
import Gridicons

// MARK: - Functionality related to sharing a blog via the reader.

extension ReaderStreamViewController {

    // MARK: Properties

    private struct Metrics {
        static let shareIconSize = CGFloat(44)  // NB : Matches size in ReaderDetailViewController
    }

    // MARK: Internal behavior

    /// Exposes the Share button if the currently selected Reader topic represents a site.
    ///
    func configureShareButtonIfNeeded() {
        guard let _ = readerTopic as? ReaderSiteTopic else {
            removeShareButton()
            return
        }

        let image = Gridicon.iconOfType(.shareIOS).withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
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

        /**
            It may seem curious that we are employing a PostSharingController to share a site (Blog).
            In this case, the Post is a `SharePost`, which can be serialized for use with `UIActivityViewController`.
         */
        sharingController.sharePost(
            sitePendingPost.title,
            summary: sitePendingPost.siteDescription,
            link: sitePendingPost.siteURL,
            fromView: sender,
            inViewController: self)
    }
}
