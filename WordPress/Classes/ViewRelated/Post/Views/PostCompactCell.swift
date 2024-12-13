import AutomatticTracks
import UIKit
import WordPressShared
import WordPressUI
import WordPressMedia

final class PostCompactCell: UITableViewCell, Reusable {
    private let titleLabel = UILabel()
    private let detailsLabel = UILabel()
    private let featuredImageView = AsyncImageView()

    private var post: Post? {
        didSet {
            guard let post, post != oldValue else { return }
            viewModel = PostCardStatusViewModel(post: post)
        }
    }

    private var viewModel: PostCardStatusViewModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupStyles()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with post: Post) {
        self.post = post

        titleLabel.text = post.titleForDisplay()
        detailsLabel.text = post.contentPreviewForDisplay()
        configureFeaturedImage()
    }

    private func setupStyles() {
        WPStyleGuide.configureTableViewCell(self)
        WPStyleGuide.applyPostCardStyle(self)

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1

        detailsLabel.font = .preferredFont(forTextStyle: .subheadline)
        detailsLabel.textColor = .secondaryLabel
        detailsLabel.numberOfLines = 1

        featuredImageView.layer.cornerRadius = Constants.imageRadius
        featuredImageView.layer.masksToBounds = true

        contentView.backgroundColor = .systemBackground
    }

    private func setupLayout() {
        let stackView = UIStackView(alignment: .top, spacing: 8, [
            UIStackView(axis: .vertical, alignment: .leading, spacing: 2, [
                titleLabel, detailsLabel
            ]),
            featuredImageView
        ])
        contentView.addSubview(stackView)
        stackView.pinEdges(insets: UIEdgeInsets(horizontal: 16, vertical: 8))

        NSLayoutConstraint.activate([
            featuredImageView.widthAnchor.constraint(equalToConstant: Constants.imageSize.width),
            featuredImageView.heightAnchor.constraint(equalToConstant: Constants.imageSize.height),
        ])
    }

    private func configureFeaturedImage() {
        featuredImageView.prepareForReuse()

        if let post, let url = post.featuredImageURL {
            featuredImageView.isHidden = false

            let host = MediaHost(with: post, failure: { error in
                // We'll log the error, so we know it's there, but we won't halt execution.
                WordPressAppDelegate.crashLogging?.logError(error)
            })

            let targetSize = Constants.imageSize.scaled(by: traitCollection.displayScale)
            featuredImageView.setImage(with: url, host: host, size: targetSize)
        } else {
            featuredImageView.isHidden = true
        }
    }

    private enum Constants {
        static let imageRadius: CGFloat = 4
        static let imageSize = CGSize(width: 40, height: 40)
    }
}
