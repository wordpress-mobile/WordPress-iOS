import UIKit
import AutomatticTracks

protocol ReaderDetailHeaderViewDelegate {
    func didTapBlogName()
    func didTapMenuButton(_ sender: UIView)
    func didTapTagButton()
    func didTapHeaderAvatar()
    func didTapFeaturedImage(_ sender: CachedAnimatedImageView)
}

class ReaderDetailHeaderView: UIStackView, NibLoadable {
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var blavatarImageView: UIImageView!
    @IBOutlet weak var blogURLLabel: UILabel!
    @IBOutlet weak var blogNameButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var featuredImageView: CachedAnimatedImageView!
    @IBOutlet weak var featuredImageBottomPaddingView: ReaderSpacerView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleBottomPaddingView: UIView!
    @IBOutlet weak var bylineView: UIView!
    @IBOutlet weak var avatarImageView: CircularImageView!
    @IBOutlet weak var bylineScrollView: UIScrollView!
    @IBOutlet weak var bylineLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet fileprivate var bylineGradientViews: [GradientView]!

    /// The post to show details in the header
    ///
    private var post: ReaderPost?

    /// Image loader for the featured image
    ///
    private lazy var featuredImageLoader: ImageLoader = {
        // Allow for large GIFs to animate on the detail page
        return ImageLoader(imageView: featuredImageView, gifStrategy: .largeGIFs)
    }()

    /// The user interface direction for the view's semantic content attribute.
    ///
    private var layoutDirection: UIUserInterfaceLayoutDirection {
        return UIView.userInterfaceLayoutDirection(for: semanticContentAttribute)
    }

    /// Any interaction with the header is sent to the delegate
    ///
    var delegate: ReaderDetailHeaderViewDelegate?

    func configure(for post: ReaderPost) {
        self.post = post

        configureSiteImage()
        configureURL()
        configureBlogName()
        configureFeaturedImage()
        configureTitle()
        configureByLine()
        configureTag()

        prepareForVoiceOver()
        prepareMenuForVoiceOver()
        preparePostTitleForVoiceOver()

        // Hide the featured image and its padding until we know there is one to load.
        featuredImageView.isHidden = true
        featuredImageBottomPaddingView.isHidden = true
    }

    @IBAction func didTapBlogName(_ sender: Any) {
        delegate?.didTapBlogName()
    }

    @IBAction func didTapMenuButton(_ sender: UIButton) {
        delegate?.didTapMenuButton(sender)
    }

    @IBAction func didTapTagButton(_ sender: Any) {
        delegate?.didTapTagButton()
    }

    @objc func didTapHeaderAvatar(_ gesture: UITapGestureRecognizer) {
        if gesture.state != .ended {
            return
        }

        delegate?.didTapHeaderAvatar()
    }

    @objc func didTapFeaturedImage(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }

        delegate?.didTapFeaturedImage(featuredImageView)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        WPStyleGuide.applyReaderCardBylineLabelStyle(bylineLabel)
        WPStyleGuide.applyReaderCardBylineLabelStyle(blogURLLabel)
        WPStyleGuide.applyReaderCardSiteButtonStyle(blogNameButton)
        WPStyleGuide.applyReaderCardTagButtonStyle(tagButton)
        WPStyleGuide.applyReaderCardTitleLabelStyle(titleLabel)
        titleLabel.backgroundColor = .basicBackground

        headerView.backgroundColor = .listForeground

        reloadGradientColors()
    }

    private func configureSiteImage() {
        let placeholder = UIImage(named: "post-blavatar-placeholder")
        blavatarImageView.image = placeholder

        let size = blavatarImageView.frame.size.width * UIScreen.main.scale
        if let url = post?.siteIconForDisplay(ofSize: Int(size)) {
            blavatarImageView.downloadImage(from: url, placeholderImage: placeholder)
        }
    }

    private func configureURL() {
        guard let siteURL = post?.siteURLForDisplay() as NSString? else {
            return
        }

        blogURLLabel.text = siteURL.components(separatedBy: "//").last
    }

    private func configureBlogName() {
        let blogName = post?.blogNameForDisplay()
        blogNameButton.setTitle(blogName, for: UIControl.State())
        blogNameButton.setTitle(blogName, for: .highlighted)
        blogNameButton.setTitle(blogName, for: .disabled)
        blogNameButton.isAccessibilityElement = false
        blogNameButton.naturalContentHorizontalAlignment = .leading

        // Enable button only if not previewing a site.
        if let topic = post?.topic {
            blogNameButton.isEnabled = !ReaderHelpers.isTopicSite(topic)
        }

        // If the button is enabled also listen for taps on the avatar.
        if blogNameButton.isEnabled {
            let tgr = UITapGestureRecognizer(target: self, action: #selector(didTapHeaderAvatar(_:)))
            blavatarImageView.addGestureRecognizer(tgr)
        }
    }

    private func configureFeaturedImage() {
        guard let post = post,
            !post.contentIncludesFeaturedImage(),
            let featuredImageURL = post.featuredImageURLForDisplay() else {
                return
        }

        let host = MediaHost(with: post, failure: { error in
            // We'll log the error, so we know it's there, but we won't halt execution.
            CrashLogging.logError(error)
        })

        let maxImageWidth = frame.width
        let imageWidthSize = CGSize(width: maxImageWidth, height: 0) // height 0: preserves aspect ratio.
        featuredImageLoader.loadImage(with: featuredImageURL, from: host, preferredSize: imageWidthSize, placeholder: nil, success: { [weak self] in
            guard let strongSelf = self, let size = strongSelf.featuredImageView.image?.size else {
                return
            }
            DispatchQueue.main.async {
                strongSelf.configureFeaturedImageConstraints(with: size)
                strongSelf.configureFeaturedImageGestures()
            }
        }) { error in
            DDLogError("Error loading featured image in reader detail: \(String(describing: error))")
        }
    }

    private func configureFeaturedImageConstraints(with size: CGSize) {
        // Unhide the views
        featuredImageView.isHidden = false
        featuredImageBottomPaddingView.isHidden = false

        // Now that we have the image, create an aspect ratio constraint for
        // the featuredImageView
        let ratio = size.height / size.width
        let constraint = NSLayoutConstraint(item: featuredImageView as Any,
                                            attribute: .height,
                                            relatedBy: .equal,
                                            toItem: featuredImageView!,
                                            attribute: .width,
                                            multiplier: ratio,
                                            constant: 0)
        constraint.priority = .defaultHigh
        featuredImageView.addConstraint(constraint)
        featuredImageView.setNeedsUpdateConstraints()
    }

    private func configureFeaturedImageGestures() {
        // Listen for taps so we can display the image detail
        let tgr = UITapGestureRecognizer(target: self, action: #selector(didTapFeaturedImage(_:)))
        featuredImageView.addGestureRecognizer(tgr)
    }

    private func configureTitle() {
        if let title = post?.titleForDisplay() {
            titleLabel.attributedText = NSAttributedString(string: title, attributes: WPStyleGuide.readerDetailTitleAttributes())
            titleLabel.isHidden = false

        } else {
            titleLabel.attributedText = nil
            titleLabel.isHidden = true
        }
    }

    private func configureByLine() {
        // Avatar
        let placeholder = UIImage(named: "gravatar")

        if let avatarURLString = post?.authorAvatarURL,
            let url = URL(string: avatarURLString) {
            avatarImageView.downloadImage(from: url, placeholderImage: placeholder)
        }

        // Byline
        let author = post?.authorForDisplay()
        let dateAsString = post?.dateForDisplay()?.mediumString()
        let byline: String

        if let author = author, let date = dateAsString {
            byline = author + " · " + date
        } else {
            byline = author ?? dateAsString ?? String()
        }

        bylineLabel.text = byline

        flipBylineViewIfNeeded()
    }

    private func flipBylineViewIfNeeded() {
        if layoutDirection == .rightToLeft {
            bylineScrollView.transform = CGAffineTransform(scaleX: -1, y: 1)
            bylineScrollView.subviews.first?.transform = CGAffineTransform(scaleX: -1, y: 1)

            for gradientView in bylineGradientViews {
                let start = gradientView.startPoint
                let end = gradientView.endPoint

                gradientView.startPoint = end
                gradientView.endPoint = start
            }
        }
    }

    private func configureTag() {
        var tag = ""
        if let rawTag = post?.primaryTag {
            if rawTag.count > 0 {
                tag = "#\(rawTag)"
            }
        }
        tagButton.isHidden = tag.count == 0
        tagButton.setTitle(tag, for: UIControl.State())
        tagButton.setTitle(tag, for: .highlighted)
    }

    private func reloadGradientColors() {
        bylineGradientViews.forEach({ view in
            view.fromColor = .basicBackground
            view.toColor = UIColor.basicBackground.withAlphaComponent(0.0)
        })
    }

    private func prepareForVoiceOver() {
        guard let post = post else {
            blogNameButton.isAccessibilityElement = false
            return
        }

        blogNameButton.isAccessibilityElement = true
        blogNameButton.accessibilityTraits = [.staticText, .button]
        blogNameButton.accessibilityHint = NSLocalizedString("Shows the site's posts.", comment: "Accessibility hint for the site name and URL button on Reader's Post Details.")
        if let label = blogNameLabel(post) {
            blogNameButton.accessibilityLabel = label
        }
    }

    private func prepareMenuForVoiceOver() {
        menuButton.accessibilityLabel = NSLocalizedString("More", comment: "Accessibility label for the More button on Reader's post details")
        menuButton.accessibilityTraits = UIAccessibilityTraits.button
        menuButton.accessibilityHint = NSLocalizedString("Shows more options.", comment: "Accessibility hint for the More button on Reader's post details")
    }

    private func blogNameLabel(_ post: ReaderPost) -> String? {
        guard let postedIn = post.blogNameForDisplay(),
            let postedBy = post.authorDisplayName,
            let postedAtURL = post.siteURLForDisplay()?.components(separatedBy: "//").last else {
                return nil
        }

        guard let postedOn = post.dateCreated?.mediumString() else {
            let format = NSLocalizedString("Posted in %@, at %@, by %@.", comment: "Accessibility label for the blog name in the Reader's post details, without date. Placeholders are blog title, blog URL, author name")
            return String(format: format, postedIn, postedAtURL, postedBy)
        }

        let format = NSLocalizedString("Posted in %@, at %@, by %@, %@", comment: "Accessibility label for the blog name in the Reader's post details. Placeholders are blog title, blog URL, author name, published date")
        return String(format: format, postedIn, postedAtURL, postedBy, postedOn)
    }

    private func preparePostTitleForVoiceOver() {
        guard let title = post?.titleForDisplay() else {
            return
        }
        isAccessibilityElement = false

        titleLabel.accessibilityLabel = title
        titleLabel.accessibilityTraits = .staticText
    }

}
