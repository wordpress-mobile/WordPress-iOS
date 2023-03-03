import UIKit

final class BlazePostPreviewView: UIView {

    // MARK: - Subviews

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [labelStackView, featuredImageView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Metrics.stackViewSpacing
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = Metrics.stackViewMargins
        return stackView
    }()

    private lazy var labelStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Metrics.labelStackViewSpacing
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.font = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .semibold)
        label.numberOfLines = 0
        label.text = post.titleForDisplay()
        label.textColor = .text
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.font = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular)
        label.numberOfLines = 0
        label.text = post.permaLink
        label.textColor = .textSubtle
        return label
    }()

    private lazy var featuredImageView: CachedAnimatedImageView = {
        let imageView = CachedAnimatedImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: Metrics.featuredImageSize),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        ])

        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Metrics.featuredImageCornerRadius

        return imageView
    }()

    // MARK: - Properties

    private let post: AbstractPost

    private lazy var imageLoader: ImageLoader = {
        return ImageLoader(imageView: featuredImageView, gifStrategy: .mediumGIFs)
    }()

    // MARK: - Initializers

    init(post: AbstractPost) {
        self.post = post
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = UIColor(light: .systemGroupedBackground, dark: .secondarySystemBackground)
        layer.cornerRadius = Metrics.cornerRadius

        addSubview(stackView)
        pinSubviewToAllEdges(stackView)

        setupFeaturedImage()
    }

    private func setupFeaturedImage() {
        if let url = post.featuredImageURL {
            featuredImageView.isHidden = false

            let host = MediaHost(with: post, failure: { error in
                // We'll log the error, so we know it's there, but we won't halt execution.
                WordPressAppDelegate.crashLogging?.logError(error)
            })

            let preferredSize = CGSize(width: featuredImageView.frame.width, height: featuredImageView.frame.height)
            imageLoader.loadImage(with: url, from: host, preferredSize: preferredSize)

        } else {
            featuredImageView.isHidden = true
        }
    }
}

extension BlazePostPreviewView {

    private enum Metrics {
        static let stackViewMargins = NSDirectionalEdgeInsets(top: 15.0, leading: 20.0, bottom: 15.0, trailing: 20.0)
        static let stackViewSpacing: CGFloat = 15.0
        static let labelStackViewSpacing: CGFloat = 5.0
        static let cornerRadius: CGFloat = 15.0
        static let featuredImageSize: CGFloat = 80.0
        static let featuredImageCornerRadius: CGFloat = 5.0
    }

}
