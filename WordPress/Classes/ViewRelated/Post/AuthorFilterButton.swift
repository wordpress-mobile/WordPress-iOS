import UIKit
import Gridicons

enum AuthorFilterType {
    case everyone
    case user(gravatarEmail: String?)
}

private extension AuthorFilterType {
    var accessibilityValue: String {
        switch self {
        case .everyone:
            return NSLocalizedString("Showing everyone's posts", comment: "Voiceover description for the post list filter which shows posts for all users on a site.")
        case .user:
            return NSLocalizedString("Showing just my posts", comment: "Voiceover description for the post list filter which shows posts for just the current user on a site.")
        }
    }
}

final class AuthorFilterButton: UIControl {
    private let authorImageView: CircularImageView = {
        let imageView = CircularImageView(image: UIImage.gravatarPlaceholderImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.tintColor = .neutral(.shade70)
        return imageView
    }()

    override var intrinsicContentSize: CGSize {
        return Metrics.contentSize
    }

    var filterType: AuthorFilterType = .everyone {
        didSet {
            switch filterType {
            case .everyone:
                authorImageView.image = UIImage(named: "icon-people")?.withTintColor(.text, renderingMode: .alwaysTemplate)
                authorImageView.contentMode = .center
            case .user(let email):
                authorImageView.contentMode = .scaleAspectFill
                if let email = email {
                    authorImageView.downloadGravatarWithEmail(email, placeholderImage: gravatarPlaceholder)
                } else {
                    authorImageView.image = gravatarPlaceholder
                }
            }

            prepareForVoiceOver()
        }
    }

    init() {
        super.init(frame: .zero)

        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    private func commonInit() {
        addSubview(authorImageView)
        NSLayoutConstraint.activate([
            authorImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.leadingPadding),
            authorImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            authorImageView.widthAnchor.constraint(equalToConstant: Metrics.gravatarSize.width),
            authorImageView.heightAnchor.constraint(equalToConstant: Metrics.gravatarSize.height),
            widthAnchor.constraint(equalToConstant: intrinsicContentSize.width)
        ])

        authorImageView.image = gravatarPlaceholder

        prepareForVoiceOver()
    }

    private let gravatarPlaceholder: UIImage = .gridicon(.user, size: Metrics.gravatarSize)

    private enum Metrics {
        static let contentSize = CGSize(width: 44.0, height: 44.0)
        static let gravatarSize = CGSize(width: 28.0, height: 28.0)
        static let leadingPadding: CGFloat = 12.0
    }
}

extension AuthorFilterButton: Accessible {
    func prepareForVoiceOver() {
        isAccessibilityElement = true
        accessibilityTraits = UIAccessibilityTraits.button
        accessibilityLabel = NSLocalizedString("Author Filter", comment: "Voiceover description of a button that allows the user to filter posts by author.")
        accessibilityHint = NSLocalizedString("Select to change the current author filter.", comment: "Voiceover hint for a button that allows the user to filter posts by author.")
        accessibilityValue = filterType.accessibilityValue
    }
}
