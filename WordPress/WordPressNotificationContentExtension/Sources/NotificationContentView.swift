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
        static let avatarDimension  = CGFloat(46)
        static let noticonOffset    = CGFloat(19)
        static let noticonDimension = CGFloat(24)
        static let noticonFontSize  = CGFloat(17)
        static let subviewSpacing   = CGFloat(12)
    }

    private struct Styles {
        /// Extracted from https://bettertogethermobile.wordpress.com/2018/06/25/ios12-rich-er-notification-design-v1-5/ via Digital Color Meter
        static let noticonBackgroundColor = UIColor(red: (82/255.0), green: (180/255.0), blue: (231/255.0), alpha: 1.0)
    }

    private let viewModel: RichNotificationViewModel

    private lazy var avatarView: CircularImageView = {
        let view = CircularImageView()

        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = WPStyleGuide.grey()

        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: Metrics.avatarDimension),
            view.heightAnchor.constraint(equalToConstant: Metrics.avatarDimension)
        ])

        return view
    }()

    private lazy var noticonContainerView: CircularImageView = {
        let view = CircularImageView()

        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Styles.noticonBackgroundColor

        view.addSubview(noticonLabel)

        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: Metrics.noticonDimension),
            view.heightAnchor.constraint(equalToConstant: Metrics.noticonDimension),
            noticonLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noticonLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        return view
    }()

    private lazy var noticonLabel: UILabel = {
        let label = UILabel()

        label.translatesAutoresizingMaskIntoConstraints = false

        label.font = UIFont.systemFont(ofSize: Metrics.noticonFontSize)
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
        label.sizeToFit()

        return label
    }()

    private lazy var bodyLabel: UILabel = {
        let label = UILabel()

        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0

        label.attributedText = viewModel.attributedBody
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

    // MARK: Private behavior

    /// Responsible for instantiation, installation & configuration of the view
    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(avatarView)
        addSubview(noticonContainerView)
        addSubview(subjectLabel)
        addSubview(bodyLabel)

        let constraints = [
            avatarView.topAnchor.constraint(equalTo: topAnchor),
            avatarView.leadingAnchor.constraint(equalTo: leadingAnchor),
            noticonContainerView.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor, constant: Metrics.noticonOffset),
            noticonContainerView.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor, constant: Metrics.noticonOffset),
            subjectLabel.topAnchor.constraint(equalTo: topAnchor),
            subjectLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: Metrics.subviewSpacing),
            subjectLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            bodyLabel.topAnchor.constraint(greaterThanOrEqualTo: avatarView.bottomAnchor, constant: Metrics.subviewSpacing),
            bodyLabel.topAnchor.constraint(greaterThanOrEqualTo: subjectLabel.bottomAnchor, constant: Metrics.subviewSpacing),
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
        guard
            let specifiedGravatar = viewModel.gravatarURLString,
            let validURL = URL(string: specifiedGravatar),
            let gravatar = Gravatar(validURL)
        else {
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
