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

    private let headerView = PostListHeaderView()
    private let titleAndSnippetLabel = UILabel()
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

        configureTitleAndSnippet(with: viewModel)

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

    private func configureTitleAndSnippet(with viewModel: PostListItemViewModel) {
        var titleAndSnippetString = NSMutableAttributedString()

        if let title = viewModel.title, !title.isEmpty {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: WPStyleGuide.fontForTextStyle(.callout, fontWeight: .semibold),
                .foregroundColor: UIColor.text
            ]
            let titleAttributedString = NSAttributedString(string: "\(title)\n", attributes: attributes)
            titleAndSnippetString.append(titleAttributedString)
        }

        if let snippet = viewModel.snippet, !snippet.isEmpty {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular),
                .foregroundColor: UIColor.textSubtle
            ]
            let snippetAttributedString = NSAttributedString(string: snippet, attributes: attributes)
            titleAndSnippetString.append(snippetAttributedString)
        }

        titleAndSnippetLabel.attributedText = titleAndSnippetString
    }

    // MARK: - Setup

    private func setupViews() {
        setupTitleAndSnippetLabel()
        setupFeaturedImageView()
        setupStatusLabel()

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubviews([
            titleAndSnippetLabel,
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

    private func setupTitleAndSnippetLabel() {
        titleAndSnippetLabel.translatesAutoresizingMaskIntoConstraints = false
        titleAndSnippetLabel.adjustsFontForContentSizeCategory = true
        titleAndSnippetLabel.numberOfLines = 3
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
