import Foundation
import UIKit
import Combine

final class PageListCell: UITableViewCell, PostSearchResultCell, Reusable {

    // MARK: - Views

    private let titleLabel = UILabel()
    private let badgeIconView = UIImageView()
    private let badgesLabel = UILabel()
    private let featuredImageView = CachedAnimatedImageView()
    private let ellipsisButton = UIButton(type: .custom)
    private let contentStackView = UIStackView()
    private var indentationIconView = UIImageView()
    private var cancellables: [AnyCancellable] = []

    // MARK: - Properties

    private lazy var imageLoader = ImageLoader(imageView: featuredImageView, loadingIndicator: SolidColorActivityIndicator())

    // MARK: - PostSearchResultCell

    var attributedText: NSAttributedString? {
        get { titleLabel.attributedText }
        set { titleLabel.attributedText = newValue }
    }

    // MARK: - Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    override func prepareForReuse() {
        super.prepareForReuse()

        imageLoader.prepareForReuse()
    }

    func configure(with viewModel: PageListItemViewModel, indentation: Int = 0, isFirstSubdirectory: Bool = false) {
        titleLabel.attributedText = viewModel.title

        badgeIconView.image = viewModel.badgeIcon
        badgeIconView.isHidden = viewModel.badgeIcon == nil
        badgesLabel.text = viewModel.badges

        featuredImageView.isHidden = viewModel.imageURL == nil
        if let imageURL = viewModel.imageURL {
            let host = MediaHost(with: viewModel.page) { error in
                WordPressAppDelegate.crashLogging?.logError(error)
            }
            imageLoader.loadImage(with: imageURL, from: host, preferredSize: Constants.imageSize)
        }

        separatorInset = UIEdgeInsets(top: 0, left: 16 + CGFloat(indentation) * 32, bottom: 0, right: 0)
        contentStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 12,
            leading: 16 + CGFloat(max(0, indentation - 1)) * 32,
            bottom: 12,
            trailing: 16
        )
        indentationIconView.isHidden = indentation == 0
        indentationIconView.alpha = isFirstSubdirectory ? 1 : 0 // Still contribute to layout
    }

    // MARK: - Setup

    private func setupViews() {
        setupLabels()
        setupFeaturedImageView()
        setupEllipsisButton()

        indentationIconView.tintColor = .secondaryLabel
        indentationIconView.image = UIImage(named: "subdirectory")
        indentationIconView.setContentHuggingPriority(.required, for: .horizontal)
        indentationIconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        let badgesStackView = UIStackView(arrangedSubviews: [
            badgeIconView, badgesLabel, UIView()
        ])
        badgesStackView.alignment = .bottom
        badgesStackView.spacing = 2

        let labelsStackView = UIStackView(arrangedSubviews: [
            titleLabel, badgesStackView
        ])
        labelsStackView.spacing = 4
        labelsStackView.axis = .vertical

        contentStackView.addArrangedSubviews([
            indentationIconView, labelsStackView, featuredImageView, ellipsisButton
        ])
        contentStackView.spacing = 8
        contentStackView.alignment = .center
        contentStackView.isLayoutMarginsRelativeArrangement = true

        NSLayoutConstraint.activate([
            badgeIconView.heightAnchor.constraint(equalToConstant: 18),
            badgeIconView.heightAnchor.constraint(equalTo: badgeIconView.widthAnchor, multiplier: 1)
        ])

        contentView.addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.pinSubviewToAllEdges(contentStackView)
    }

    private func setupLabels() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 1

        badgeIconView.tintColor = UIColor.secondaryLabel

        badgesLabel.font = WPStyleGuide.fontForTextStyle(.footnote)
        badgesLabel.textColor = UIColor.secondaryLabel
    }

    private func setupFeaturedImageView() {
        featuredImageView.translatesAutoresizingMaskIntoConstraints = false
        featuredImageView.contentMode = .scaleAspectFill
        featuredImageView.layer.masksToBounds = true
        featuredImageView.layer.cornerRadius = 5

        NSLayoutConstraint.activate([
            featuredImageView.widthAnchor.constraint(equalToConstant: Constants.imageSize.width),
            featuredImageView.heightAnchor.constraint(equalToConstant: Constants.imageSize.height),
        ])
    }

    private func setupEllipsisButton() {
        ellipsisButton.translatesAutoresizingMaskIntoConstraints = false
        ellipsisButton.setImage(UIImage(named: "more-horizontal-mobile"), for: .normal)
        ellipsisButton.tintColor = .listIcon

        NSLayoutConstraint.activate([
            ellipsisButton.widthAnchor.constraint(equalToConstant: 24)
        ])
    }
}

private enum Constants {
    static let imageSize = CGSize(width: 44, height: 44)
}
