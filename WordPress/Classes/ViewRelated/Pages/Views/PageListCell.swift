import Foundation
import UIKit
import Combine

final class PageListCell: UITableViewCell, AbstractPostListCell, PostSearchResultCell, Reusable {

    // MARK: - Views

    private let titleLabel = UILabel()
    private let badgeIconView = UIImageView()
    private let badgesLabel = UILabel()
    private let featuredImageView = AsyncImageView()
    private let icon = UIImageView()
    private let indicator = UIActivityIndicatorView(style: .medium)
    private let ellipsisButton = UIButton(type: .custom)
    private let contentStackView = UIStackView()
    private var indentationIconView = UIImageView()
    private var viewModel: PageListItemViewModel?

    // MARK: - PostSearchResultCell

    var attributedText: NSAttributedString? {
        get { titleLabel.attributedText }
        set { titleLabel.attributedText = newValue }
    }

    // MARK: AbstractPostListCell

    var post: AbstractPost? { viewModel?.page }

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

        featuredImageView.prepareForReuse()
        viewModel = nil
    }

    func configure(with viewModel: PageListItemViewModel, indentation: Int = 0, isFirstSubdirectory: Bool = false, delegate: InteractivePostViewDelegate? = nil) {
        if let delegate {
            configureEllipsisButton(with: viewModel.page, delegate: delegate)
        }

        titleLabel.attributedText = viewModel.title

        badgeIconView.image = viewModel.badgeIcon
        badgeIconView.isHidden = viewModel.badgeIcon == nil
        badgesLabel.attributedText = viewModel.badges

        featuredImageView.isHidden = viewModel.imageURL == nil
        if let imageURL = viewModel.imageURL {
            let host = MediaHost(with: viewModel.page) { error in
                WordPressAppDelegate.crashLogging?.logError(error)
            }
            let thumbnailURL = MediaImageService.getResizedImageURL(for: imageURL, blog: viewModel.page.blog, size: Constants.imageSize.scaled(by: UIScreen.main.scale))
            featuredImageView.setImage(with: thumbnailURL, host: host)
        }

        contentStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0,
            leading: CGFloat(max(0, indentation - 1)) * 32,
            bottom: 0,
            trailing: 0
        )
        indentationIconView.isHidden = indentation == 0
        indentationIconView.alpha = isFirstSubdirectory ? 1 : 0 // Still contribute to layout

        configure(with: viewModel.syncStateViewModel)
        self.viewModel = viewModel
    }

    private func configure(with viewModel: PostSyncStateViewModel) {
        contentView.isUserInteractionEnabled = viewModel.isEditable

        titleLabel.alpha = viewModel.isEditable ? 1 : 0.5
        contentStackView.alpha = viewModel.isEditable ? 1 : 0.5

        if let iconInfo = viewModel.iconInfo {
            icon.image = iconInfo.image
            icon.tintColor = iconInfo.color
        }

        ellipsisButton.isHidden = !viewModel.isShowingEllipsis
        icon.isHidden = viewModel.iconInfo == nil
        indicator.isHidden = !viewModel.isShowingIndicator

        if viewModel.isShowingIndicator {
            indicator.startAnimating()
        }
    }

    private func configureEllipsisButton(with page: Page, delegate: InteractivePostViewDelegate) {
        ellipsisButton.showsMenuAsPrimaryAction = true
        ellipsisButton.menu = AbstractPostMenuHelper(page).makeMenu(presentingView: ellipsisButton, delegate: delegate)
    }

    // MARK: - Setup

    private func setupViews() {
        setupLabels()
        setupFeaturedImageView()
        setupEllipsisButton()
        setupIcon()

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
            indentationIconView, labelsStackView, UIView(), icon, indicator, featuredImageView, ellipsisButton
        ])
        contentStackView.spacing = 8
        contentStackView.alignment = .center
        contentStackView.isLayoutMarginsRelativeArrangement = true

        indicator.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        NSLayoutConstraint.activate([
            badgeIconView.heightAnchor.constraint(equalToConstant: 18),
            badgeIconView.heightAnchor.constraint(equalTo: badgeIconView.widthAnchor, multiplier: 1)
        ])

        contentView.addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.pinSubviewToAllEdgeMargins(contentStackView)
    }

    private func setupLabels() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 1

        badgeIconView.tintColor = UIColor.secondaryLabel
    }

    private func setupIcon() {
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22)
        ])
        icon.contentMode = .scaleAspectFit
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
        ellipsisButton.tintColor = .secondaryLabel

        NSLayoutConstraint.activate([
            ellipsisButton.widthAnchor.constraint(equalToConstant: 24)
        ])
    }
}

private enum Constants {
    static let imageSize = CGSize(width: 44, height: 44)
}
