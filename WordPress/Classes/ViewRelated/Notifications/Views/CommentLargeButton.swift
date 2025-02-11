import UIKit
import WordPressUI
import WordPressShared

final class CommentLargeButton: UIButton {
    private let iconView = MyProfileIconView(hidesWhenEmpty: true)
    private var containerView = UIView()
    private let placeholderLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)!
        setupView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        containerView.layer.cornerRadius = containerView.bounds.height / 2
        containerView.layer.masksToBounds = true
    }

    var placeholder: String? {
        set { placeholderLabel.text = newValue }
        get { placeholderLabel.text }
    }

    private func setupView() {
        accessibilityIdentifier = "button_add_comment_large"
        accessibilityLabel = NSLocalizedString("addCommentButton.accessibilityIdentifity", value: "Add Comment", comment: "Accessibility identifier for an 'Add Comment' button")

        placeholderLabel.textColor = .tertiaryLabel

        placeholderLabel.text = CommentComposerViewModel.leaveCommentLocalizedPlaceholder

        containerView.addSubview(placeholderLabel)
        containerView.backgroundColor = .secondarySystemBackground
        placeholderLabel.pinEdges(insets: UIEdgeInsets(horizontal: 14, vertical: 10))

        let stackView = UIStackView(alignment: .center, spacing: 8, [iconView, containerView])
        addSubview(stackView)
        stackView.pinEdges(insets: UIEdgeInsets.init(top: 14, left: 20, bottom: 8, right: 20))

        let divider = SeparatorView.horizontal()
        addSubview(divider)
        divider.pinEdges([.top, .horizontal])
    }
}
