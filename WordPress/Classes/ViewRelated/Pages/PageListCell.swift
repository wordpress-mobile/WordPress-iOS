import Foundation
import UIKit
import Combine

final class PageListCell: UITableViewCell, Reusable {

    // MARK: - Views

    private let titleLabel = UILabel()
    private let badgeIconView = UIImageView()
    private let badgesLabel = UILabel()
    private let featuredImageView = CachedAnimatedImageView()
    private let ellipsisButton = UIButton(type: .custom)
    private var cancellables: [AnyCancellable] = []

    // MARK: - Properties

    private lazy var imageLoader = ImageLoader(imageView: featuredImageView, loadingIndicator: SolidColorActivityIndicator())

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

        cancellables = []
        imageLoader.prepareForReuse()
    }

    func configure(with viewModel: PageListItemViewModel) {
        viewModel.$title.sink { [titleLabel] in
            titleLabel.attributedText = $0
        }.store(in: &cancellables)

        badgeIconView.image = viewModel.badgeIcon
        badgeIconView.isHidden = viewModel.badgeIcon == nil
        badgesLabel.text = viewModel.badges

        imageLoader.prepareForReuse()
        featuredImageView.isHidden = viewModel.imageURL == nil
        if let imageURL = viewModel.imageURL {
            let host = MediaHost(with: viewModel.page) { error in
                WordPressAppDelegate.crashLogging?.logError(error)
            }
            imageLoader.loadImage(with: imageURL, from: host, preferredSize: Constants.imageSize)
        }
    }

    // MARK: - Setup

    private func setupViews() {
        separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)

        setupLabels()
        setupFeaturedImageView()
        setupEllipsisButton()

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

        let contentStackView = UIStackView(arrangedSubviews: [
            labelsStackView, featuredImageView, ellipsisButton
        ])
        contentStackView.spacing = 8
        contentStackView.alignment = .center
        contentStackView.isLayoutMarginsRelativeArrangement = true
        contentStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)

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
