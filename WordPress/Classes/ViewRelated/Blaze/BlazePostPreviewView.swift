import UIKit

final class BlazePostPreviewView: UIView {

    // MARK: - Subviews

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [labelStackView, featuredImageView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Metrics.stackViewSpacing
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.distribution = .fill
        return stackView
    }()

    private lazy var labelStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Metrics.stackViewSpacing
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
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
        label.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        label.numberOfLines = 0
        label.text = post.permaLink
        label.textColor = .textSubtle
        return label
    }()

    private lazy var featuredImageView: CachedAnimatedImageView = {
        let imageView = CachedAnimatedImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
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
        backgroundColor = .systemGroupedBackground
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

            imageLoader.loadImage(with: url, from: host, preferredSize: CGSize(width: featuredImageView.frame.width, height: featuredImageView.frame.height))
        } else {
            featuredImageView.isHidden = true
        }
    }
}

extension BlazePostPreviewView {

    private enum Metrics {
        static let stackViewSpacing: CGFloat = 16.0
        static let cornerRadius: CGFloat = 16.0
    }

}
