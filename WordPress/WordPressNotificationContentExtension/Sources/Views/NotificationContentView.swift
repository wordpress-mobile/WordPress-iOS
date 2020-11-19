import UIKit

import WordPressShared
import WordPressUI

// MARK: - NotificationContentView

/// This class is responsible for presenting the content of a rich notification within the "Long Look".
/// It consists of an avatar view, "noticon", subject, & body.
///
class NotificationContentView: UIView {

    // MARK: Properties

    private struct Metrics {
        static let avatarTopInset           = CGFloat(4)
        static let avatarDimension          = CGFloat(32)
        static let noticonOffset            = CGFloat(12)
        static let noticonInnerDimension    = CGFloat(14)
        static let noticonOuterDimension    = CGFloat(18)
        static let noticonFontSize          = CGFloat(12)
        static let subviewSpacing           = CGFloat(12)
    }

    private struct Styles {
        // NB: Matches `noticonUnreadColor` in NoteTableViewCell
        static let noticonInnerBackgroundColor = UIColor(red: 0x25/255.0, green: 0x9C/255.0, blue: 0xCF/255.0, alpha: 0xFF/255.0)

        // NB: Matches `noteBackgroundReadColor` in `NoteTableViewCell`
        static let noticonOuterBackgroundColor = UIColor.white
    }

    private let viewModel: RichNotificationViewModel

    private lazy var avatarView: CircularImageView = {
        let view = CircularImageView()

        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.neutral(.shade30)

        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: Metrics.avatarDimension),
            view.heightAnchor.constraint(equalToConstant: Metrics.avatarDimension)
        ])

        view.isHidden = self.viewModel.gravatarURLString == nil

        return view
    }()

    private lazy var noticonContainerView: CircularImageView = {
        let view = CircularImageView()

        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Styles.noticonOuterBackgroundColor

        view.addSubview(noticonView)

        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: Metrics.noticonOuterDimension),
            view.heightAnchor.constraint(equalToConstant: Metrics.noticonOuterDimension),
            noticonView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noticonView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        view.isHidden = self.viewModel.gravatarURLString == nil

        return view
    }()

    private lazy var noticonView: CircularImageView = {
        let view = CircularImageView()

        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Styles.noticonInnerBackgroundColor

        view.addSubview(noticonLabel)

        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: Metrics.noticonInnerDimension),
            view.heightAnchor.constraint(equalToConstant: Metrics.noticonInnerDimension),
            noticonLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noticonLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        return view
    }()

    private lazy var noticonLabel: UILabel = {
        let label = UILabel()

        label.translatesAutoresizingMaskIntoConstraints = false

        label.font = UIFont(name: "Noticons", size: Metrics.noticonFontSize)!
        label.text = viewModel.noticon ?? ""

        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 1

        label.text = viewModel.noticon ?? ""
        label.sizeToFit()

        return label
    }()

    private lazy var subjectLabel: UILabel = {
        let label = UILabel()

        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0

        label.attributedText = viewModel.attributedSubject
        label.textColor = .text
        label.sizeToFit()

        return label
    }()

    private lazy var bodyLabel: UILabel = {
        let label = UILabel()

        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0

        label.attributedText = viewModel.attributedBody
        label.textColor = .textSubtle
        label.sizeToFit()

        return label
    }()

    // MARK: NotificationContentView

    init(viewModel: RichNotificationViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupView()
    }

    // MARK: UIView

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Reload the content when the trait did change
    func reloadContent() {
        subjectLabel.attributedText = viewModel.attributedSubject
        subjectLabel.textColor = .text

        bodyLabel.attributedText = viewModel.attributedBody
        bodyLabel.textColor = .textSubtle
    }

    // MARK: Private behavior

    /// Responsible for instantiation, installation & configuration of the view
    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(avatarView)
        addSubview(noticonContainerView)
        addSubview(subjectLabel)
        addSubview(bodyLabel)

        let constraints = [
            avatarView.topAnchor.constraint(equalTo: subjectLabel.topAnchor, constant: Metrics.avatarTopInset),
            avatarView.leadingAnchor.constraint(equalTo: leadingAnchor),
            noticonContainerView.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor, constant: Metrics.noticonOffset),
            noticonContainerView.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor, constant: Metrics.noticonOffset),
            subjectLabel.topAnchor.constraint(equalTo: topAnchor),
            subjectLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: Metrics.subviewSpacing),
            subjectLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            bodyLabel.topAnchor.constraint(greaterThanOrEqualTo: subjectLabel.bottomAnchor),
            bodyLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            bodyLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)

        downloadGravatar()
    }
}

// MARK: - Adapted from NoteTableViewCell for this extension

extension NotificationContentView {
    func downloadGravatar() {
        guard let specifiedGravatar = viewModel.gravatarURLString,
            let validURL = URL(string: specifiedGravatar),
            let gravatar = Gravatar(validURL) else {

            return
        }

        avatarView.downloadGravatar(
            gravatar,
            placeholder: UIImage(), // Long Look is not visible right away...
            animate: true,
            failure: { error in
                debugPrint(String(describing: error?.localizedDescription))
        })
    }
}
