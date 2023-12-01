/// A seasonal card view shown in the WordPress app to promote State of the Word 2023.
///
class SOTWCardView: UIView {

    // MARK: - Views

    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.setText(Strings.body)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var watchNowButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.button, for: .normal)
        button.setTitleColor(.primary, for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(onButtonTap), for: .touchUpInside)
        return button
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [bodyLabel, watchNowButton])
        stackView.axis = .vertical
        stackView.spacing = 12.0
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.setTitle(Strings.title)
        frameView.onEllipsisButtonTap = {}
        frameView.ellipsisButton.showsMenuAsPrimaryAction = true
        frameView.ellipsisButton.menu = nil // TODO.
        frameView.add(subview: contentStackView)

        return frameView
    }()
}

private extension SOTWCardView {

    @objc func onButtonTap() {
        // TODO: Redirect to livestream landing page.
    }

    struct Strings {
        static let title = "State of the Word 2023"
        static let body = "Check out WordPress co-founder Matt Mullenweg's annual keynote to stay on top of what's coming in 2024 and beyond."
        static let button = "Watch now"
    }
}
