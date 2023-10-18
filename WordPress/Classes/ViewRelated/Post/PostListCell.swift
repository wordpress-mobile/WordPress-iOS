import Foundation
import UIKit

final class PostListCell: UITableViewCell, Reusable {

    // MARK: - Views

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        return stackView
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    private let headerView = PostListHeaderView()
    private let titleLabel = UILabel()
    private let snippetLabel = UILabel()
    private let featuredImageView = CachedAnimatedImageView()
    private let statusLabel = UILabel()

    // MARK: - Properties

    private lazy var imageLoader = ImageLoader(imageView: featuredImageView)

    // MARK: - Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func configure(with viewModel: PostListItemViewModel) {
        headerView.configure(with: viewModel)

        if let title = viewModel.title, !title.isEmpty {
            titleLabel.text = title
            titleLabel.isHidden = false
        } else {
            titleLabel.isHidden = true
        }

        if let snippet = viewModel.snippet, !snippet.isEmpty {
            snippetLabel.text = snippet
            snippetLabel.isHidden = false
        } else {
            snippetLabel.isHidden = true
        }

        titleLabel.numberOfLines = snippetLabel.isHidden ? 3 : 2
        snippetLabel.numberOfLines = titleLabel.isHidden ? 3 : 2
        
        imageLoader.prepareForReuse()
        featuredImageView.isHidden = viewModel.imageURL == nil
        if let imageURL = viewModel.imageURL {
            let host = MediaHost(with: viewModel.post) { error in
                WordPressAppDelegate.crashLogging?.logError(error)
            }
            let preferredSize = CGSize(width: 44, height: 44)
            imageLoader.loadImage(with: imageURL, from: host, preferredSize: preferredSize)
        }

        statusLabel.text = viewModel.status
        statusLabel.textColor = viewModel.statusColor
        statusLabel.isHidden = viewModel.status.isEmpty
    }

    // MARK: - Setup

    private func setupViews() {
        setupTitleLabel()
        setupSnippetLabel()
        setupFeaturedImageView()
        setupStatusLabel()

        textStackView.translatesAutoresizingMaskIntoConstraints = false
        textStackView.addArrangedSubviews([
            titleLabel,
            snippetLabel
        ])
        textStackView.spacing = 2

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubviews([
            textStackView,
            featuredImageView
        ])
        contentStackView.spacing = 16
        contentStackView.alignment = .top

        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.addArrangedSubviews([
            headerView,
            contentStackView,
            statusLabel
        ])
        mainStackView.spacing = 4
        mainStackView.isLayoutMarginsRelativeArrangement = true
        mainStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)

        contentView.addSubview(mainStackView)
        contentView.pinSubviewToAllEdges(mainStackView)
        contentView.backgroundColor = .systemBackground
    }

    private func setupTitleLabel() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 2
        titleLabel.textColor = .text
        titleLabel.font = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .semibold)
    }

    private func setupSnippetLabel() {
        snippetLabel.translatesAutoresizingMaskIntoConstraints = false
        snippetLabel.adjustsFontForContentSizeCategory = true
        snippetLabel.numberOfLines = 2
        snippetLabel.textColor = .textSubtle
        snippetLabel.font = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular)
    }

    private func setupFeaturedImageView() {
        featuredImageView.translatesAutoresizingMaskIntoConstraints = false
        featuredImageView.contentMode = .scaleAspectFill
        featuredImageView.layer.masksToBounds = true
        featuredImageView.layer.cornerRadius = 5

        NSLayoutConstraint.activate([
            featuredImageView.widthAnchor.constraint(equalToConstant: 64),
            featuredImageView.heightAnchor.constraint(equalToConstant: 64),
        ])
    }

    private func setupStatusLabel() {
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.numberOfLines = 1
        statusLabel.font = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular)
    }
}
