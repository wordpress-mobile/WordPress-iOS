import UIKit

final class PostListHeaderView: UIView {

    // MARK: - Views

    private let textLabel = UILabel()
    private let ellipsisButton = UIButton(type: .custom)

    // MARK: - Properties

    private var post: Post?
    private var viewModel: PostListItemViewModel?

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func configure(with viewModel: PostListItemViewModel, delegate: InteractivePostViewDelegate? = nil) {
        if let delegate {
            configureEllipsisButton(with: viewModel.post, delegate: delegate)
        }
        textLabel.attributedText = viewModel.badges
    }

    private func configureEllipsisButton(with post: Post, delegate: InteractivePostViewDelegate) {
        let menuHelper = AbstractPostMenuHelper(post)
        ellipsisButton.showsMenuAsPrimaryAction = true
        ellipsisButton.menu = menuHelper.makeMenu(presentingView: ellipsisButton, delegate: delegate)
    }

    // MARK: - Setup

    private func setupView() {
        setupEllipsisButton()

        let stackView = UIStackView(arrangedSubviews: [textLabel, ellipsisButton])
        stackView.spacing = 12
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(stackView)
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
