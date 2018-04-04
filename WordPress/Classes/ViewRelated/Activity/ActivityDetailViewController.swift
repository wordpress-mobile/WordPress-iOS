import UIKit
import Gridicons

class ActivityDetailViewController: UIViewController {

    let activity: Activity
    weak var rewindPresenter: ActivityRewindPresenter?

    // MARK: - Constructors
    init(activity: Activity, rewindPresenter: ActivityRewindPresenter) {
        self.activity = activity
        self.rewindPresenter = rewindPresenter
        super.init(nibName: nil, bundle: nil)
        title = NSLocalizedString("Event", comment: "Title for the activity detail view")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        setupViews()
    }

    @objc func rewindButtonTapped(sender: UIButton) {
        rewindPresenter?.presentRewindFor(activity: activity)
    }

    private func setupViews() {
        view.backgroundColor = WPStyleGuide.greyLighten30()

        let containerView = UIView(frame: .zero)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .white
        // UIStackView is non-drawing, so we can't set a background color directly.

        let stackView = UIStackView(frame: .zero)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Constants.bottomMarginSize
        stackView.axis = .vertical

        stackView.addArrangedSubview(headerStackView())
        stackView.addArrangedSubview(contentStackView())

        if activity.isRewindable {
            stackView.addArrangedSubview(rewindStackView())
        }

        containerView.addSubview(stackView)

        view.addSubview(containerView)

        containerView.topAnchor.constraint(equalTo: view.topAnchor) .isActive = true
        containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Constants.marginSize).isActive = true
        stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Constants.marginSize).isActive = true
        stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Constants.marginSize).isActive = true

        let bottomMargin: CGFloat
        if activity.isRewindable {
            bottomMargin = 0
        } else {
            bottomMargin = -Constants.bottomMarginSize
        }

        stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: bottomMargin).isActive = true
    }
    

    private func headerStackView() -> UIStackView {
        let stackView = UIStackView(frame: .zero)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = Constants.horizontalStackViewSpacing
        stackView.alignment = .center

        let imageView = CircularImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .white
        imageView.widthAnchor.constraint(equalToConstant: Constants.avatarImageSize).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: Constants.avatarImageSize).isActive = true

        if let avatar = activity.actor?.avatarURL, let avatarURL = URL(string: avatar) {
            imageView.backgroundColor = WPStyleGuide.greyLighten10()
            imageView.downloadImage(avatarURL, placeholderImage: Gridicon.iconOfType(.user, withSize: Constants.gridiconSize))
        } else if let iconType = WPStyleGuide.ActivityStyleGuide.getGridiconTypeForActivity(activity) {
            imageView.contentMode = .center
            imageView.backgroundColor = WPStyleGuide.ActivityStyleGuide.getColorByActivityStatus(activity)
            let image = Gridicon.iconOfType(iconType, withSize: Constants.gridiconSize)
            imageView.image = image
        } else {
            imageView.isHidden = true
        }

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(nameAndRoleStackView())
        stackView.addArrangedSubview(dateStackView())

        return stackView
    }

    private func nameAndRoleStackView() -> UIStackView {
        let nameLabel = UILabel(frame: .zero)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize,
                                           weight: .semibold)
        nameLabel.textColor = WPStyleGuide.darkGrey()
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let roleLabel = UILabel(frame: .zero)
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        roleLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        roleLabel.textColor = WPStyleGuide.darkGrey()
        roleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let stackView = UIStackView(frame: .zero)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Constants.verticalStackViewSpacing
        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(roleLabel)

        nameLabel.text = activity.actor?.displayName
        roleLabel.text = activity.actor?.role

        return stackView
    }

    private func dateStackView() -> UIStackView {
        let dateLabel = UILabel(frame: .zero)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.textAlignment = .right
        dateLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        dateLabel.textColor = WPStyleGuide.darkGrey()

        let timeLabel = UILabel(frame: .zero)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.textAlignment = .right
        timeLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        timeLabel.textColor = WPStyleGuide.darkGrey()

        let stackView = UIStackView(frame: .zero)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Constants.verticalStackViewSpacing
        stackView.addArrangedSubview(dateLabel)
        stackView.addArrangedSubview(timeLabel)

        dateLabel.text = activity.publishedDateUTCWithoutTime

        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        timeFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        timeLabel.text = timeFormatter.string(from: activity.published)

        return stackView
    }

    private func contentStackView() -> UIStackView {
        let titleLabel = UILabel(frame: .zero)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)
        titleLabel.textColor = WPStyleGuide.darkGrey()
        titleLabel.numberOfLines = 0

        let contentLabel = UILabel(frame: .zero)
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.font = UIFont.preferredFont(forTextStyle: .body)
        contentLabel.textColor = WPStyleGuide.greyDarken10()
        contentLabel.numberOfLines = 0

        titleLabel.text = activity.text
        contentLabel.text = activity.summary

        let stackView = UIStackView(frame: .zero)
        stackView.axis = .vertical
        stackView.spacing = Constants.verticalStackViewSpacing

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(contentLabel)

        return stackView
    }

    private func rewindStackView() -> UIStackView {
        let hairlineView = UIView(frame: .zero)
        hairlineView.translatesAutoresizingMaskIntoConstraints = false
        hairlineView.backgroundColor = WPStyleGuide.greyLighten30()

        hairlineView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(rewindButtonTapped(sender:)), for: .touchUpInside)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        button.tintColor = WPStyleGuide.mediumBlue()
        button.contentHorizontalAlignment = .left
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: Constants.titleEdgeInset, bottom: 0, right: 0)

        button.heightAnchor.constraint(equalToConstant: Constants.buttonHeight).isActive = true

        button.setImage(Gridicon.iconOfType(.history, withSize: Constants.gridiconSize), for: .normal)
        button.setTitleColor(WPStyleGuide.mediumBlue(), for: .normal)
        button.setTitle("Rewind", for: .normal)

        let stackView = UIStackView(frame: .zero)
        stackView.axis = .vertical

        stackView.addArrangedSubview(hairlineView)
        stackView.addArrangedSubview(button)

        hairlineView.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true

        return stackView
    }

    private enum Constants {
        static let verticalStackViewSpacing: CGFloat = 2
        static let horizontalStackViewSpacing: CGFloat = 10
        static let avatarImageSize: CGFloat = 36
        static let marginSize: CGFloat = 16
        static let bottomMarginSize: CGFloat = 30
        static let gridiconSize: CGSize = CGSize(width: 24, height: 24)
        static let buttonHeight: CGFloat = 44
        static let titleEdgeInset: CGFloat = 6
    }

}

