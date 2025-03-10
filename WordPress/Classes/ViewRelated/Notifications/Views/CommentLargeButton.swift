import UIKit
import WordPressUI
import WordPressShared

final class CommentLargeButton: UIView {
    private let iconView = MyProfileIconView(hidesWhenEmpty: true)
    private var containerView = CommentLargeButtonContainerView()
    private let placeholderLabel = UILabel()
    private let button = UIButton()
    private let commentsClosedView = makeCommentsClosedView()
    private var contentStackView: UIStackView?

    @objc var isCommentingClosed = false {
        didSet {
            contentStackView?.isHidden = isCommentingClosed
            commentsClosedView.isHidden = !isCommentingClosed
            isUserInteractionEnabled = !isCommentingClosed
        }
    }

    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)!
        setupView()
    }

    var placeholder: String? {
        set { placeholderLabel.text = newValue }
        get { placeholderLabel.text }
    }

    private func setupView() {
        accessibilityIdentifier = "button_add_comment_large"
        accessibilityLabel = NSLocalizedString("addCommentButton.accessibilityIdentifity", value: "Add Comment", comment: "Accessibility identifier for an 'Add Comment' button")

        backgroundColor = .systemBackground

        placeholderLabel.textColor = .tertiaryLabel

        placeholderLabel.text = CommentCreateViewModel.leaveCommentLocalizedPlaceholder

        containerView.addSubview(placeholderLabel)
        placeholderLabel.pinEdges(insets: UIEdgeInsets(horizontal: 14, vertical: 10))

        let stackView = UIStackView(alignment: .center, spacing: 8, [iconView, containerView])
        addSubview(stackView)
        stackView.pinEdges(to: safeAreaLayoutGuide, insets: UIEdgeInsets.init(top: 14, left: 20, bottom: 8, right: 20))
        self.contentStackView = stackView

        let divider = SeparatorView.horizontal()
        addSubview(divider)
        divider.pinEdges([.top, .horizontal])

        addSubview(button)
        button.addTarget(self, action: #selector(buttonTapped), for: .primaryActionTriggered)
        button.pinEdges() // Make sure it covers everything

        addSubview(commentsClosedView)
        commentsClosedView.pinCenter(to: stackView)
        commentsClosedView.isHidden = true
    }

    @objc private func buttonTapped() {
        onTap?()
    }
}

private final class CommentLargeButtonContainerView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()

        backgroundColor = .secondarySystemBackground

        layer.cornerRadius = bounds.height / 2
        layer.masksToBounds = true
    }
}

private func makeCommentsClosedView() -> UIView {
    let font = UIFont.preferredFont(forTextStyle: .headline)

    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle")?.applyingSymbolConfiguration(.init(font: font)))
    imageView.tintColor = .label

    let titleLabel = UILabel()
    titleLabel.font = font
    titleLabel.text = Strings.commentsClosed

    let stackView = UIStackView(spacing: 8, [imageView, titleLabel])

    let containerView = CommentLargeButtonContainerView()
    containerView.addSubview(stackView)
    stackView.pinEdges(insets: UIEdgeInsets(horizontal: 14, vertical: 10))

    return containerView
}

private enum Strings {
    static let commentsClosed = NSLocalizedString("reader.comments.commentsClosed", value: "Comments Closed", comment: "Informational message, should be short.")
}
