/// A subclass implementation of `UITableViewHeaderFooterView` that displays a text with a tappable link.
/// Specifically used for Twitter deprecation purposes.
///
@objc class TwitterDeprecationTableFooterView: UITableViewHeaderFooterView {

    // The view controller that will present the web view.
    @objc weak var presentingViewController: UIViewController? = nil

    // For tracking purposes. See https://wp.me/pctCYC-OI#tracks
    @objc var source: String? = nil

    private let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = Constants.lineHeightMultiple

        let attributedString = NSMutableAttributedString(string: "\(Constants.deprecationNoticeText) ", attributes: [
            .paragraphStyle: paragraphStyle
        ])

        if let attachmentURL = Constants.blogPostURL {
            let hyperlinkText = NSAttributedString(string: Constants.hyperlinkText, attributes: [
                .paragraphStyle: paragraphStyle,
                .attachment: attachmentURL,
                .foregroundColor: AppStyleGuide.brand
            ])
            attributedString.append(hyperlinkText)
        }

        label.attributedText = attributedString
        label.isUserInteractionEnabled = true

        return label
    }()

    // MARK: Methods

    override public init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }
}

// MARK: - Private methods

private extension TwitterDeprecationTableFooterView {

    func setupSubviews() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
        label.addGestureRecognizer(tapGesture)

        contentView.addSubview(label)
        contentView.pinSubviewToAllEdgeMargins(label)
    }

    @objc func labelTapped(_ sender: UITapGestureRecognizer) {
        guard let presentingViewController,
              let source,
              let attributedText = label.attributedText else {
            return
        }

        // detect the tap location within the attributed text.
        let location = sender.location(in: label)
        let textStorage = NSTextStorage(attributedString: attributedText)
        let textContainer = NSTextContainer(size: label.bounds.size)
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines

        let characterIndex = layoutManager.characterIndex(for: location,
                                                          in: textContainer,
                                                          fractionOfDistanceBetweenInsertionPoints: nil)

        guard characterIndex < textStorage.length else {
            return
        }

        let attributes = attributedText.attributes(at: characterIndex, effectiveRange: nil)
        guard let attachmentURL = attributes[.attachment] as? URL else {
            return
        }

        WPAnalytics.track(.jetpackSocialTwitterNoticeLinkTapped, properties: ["source": source])

        // Ideally this shouldn't be the responsibility of this class, but I'm keeping it simple since it's temporary.
        let webViewController = WebViewControllerFactory.controller(url: attachmentURL, source: source)
        let navigationController = UINavigationController(rootViewController: webViewController)
        presentingViewController.present(navigationController, animated: true)
    }

    // MARK: Constants

    enum Constants {
        // adjust attributedText's line height. The default settings look slightly stretched.
        static let lineHeightMultiple = 0.9

        static let blogPostURL = URL(string: "https://wordpress.com/blog/2023/04/29/why-twitter-auto-sharing-is-coming-to-an-end/")

        static let deprecationNoticeText = NSLocalizedString(
            "social.twitterDeprecation.text",
            value: "Twitter auto-sharing is no longer available due to Twitter's changes in terms and pricing.",
            comment: "A smallprint that hints the reason behind why Twitter is deprecated."
        )

        static let hyperlinkText = NSLocalizedString(
            "social.twitterDeprecation.link",
            value: "Find out more",
            comment: "Text for a hyperlink that allows the user to learn more about the Twitter deprecation."
        )
    }
}
