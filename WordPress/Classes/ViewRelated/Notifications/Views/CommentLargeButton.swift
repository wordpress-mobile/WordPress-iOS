import UIKit
import WordPressUI
import WordPressShared

final class CommentLargeButton: UIView {
    private let iconView = MyProfileIconView(hidesWhenEmpty: true)
    private var containerView = CommentLargeButtonContainerView()
    private let placeholderLabel = UILabel()
    private let button = UIButton()

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

        placeholderLabel.text = CommentComposerViewModel.leaveCommentLocalizedPlaceholder

        containerView.addSubview(placeholderLabel)
        containerView.backgroundColor = .secondarySystemBackground
        placeholderLabel.pinEdges(insets: UIEdgeInsets(horizontal: 14, vertical: 10))

        let stackView = UIStackView(alignment: .center, spacing: 8, [iconView, containerView])
        addSubview(stackView)
        stackView.pinEdges(to: safeAreaLayoutGuide, insets: UIEdgeInsets.init(top: 14, left: 20, bottom: 8, right: 20))

        let divider = SeparatorView.horizontal()
        addSubview(divider)
        divider.pinEdges([.top, .horizontal])

        addSubview(button)
        button.addTarget(self, action: #selector(buttonTapped), for: .primaryActionTriggered)
        button.pinEdges() // Make sure it covers everything
    }

    @objc private func buttonTapped() {
        onTap?()
    }
}

private final class CommentLargeButtonContainerView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.height / 2
        layer.masksToBounds = true
    }
}
