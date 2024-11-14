import UIKit
import WordPressShared
import WordPressUI

final class ReaderTagStreamHeader: ReaderBaseHeaderView, ReaderStreamHeader {
    private let titleLabel = UILabel()
    private let followButton = UIButton()

    public weak var delegate: ReaderStreamHeaderDelegate?

    // MARK: - Lifecycle Methods

    override init(frame: CGRect) {
        super.init(frame: frame)

        let stackView = UIStackView(axis: .vertical, alignment: .leading, spacing: 12, [
            titleLabel, followButton
        ])
        contentView.addSubview(stackView)
        stackView.pinEdges()

        applyStyles()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func applyStyles() {
        WPStyleGuide.applyReaderStreamHeaderTitleStyle(titleLabel)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            WPStyleGuide.applyReaderFollowButtonStyle(followButton)
        }
    }

    // MARK: - Configuration

    public func configureHeader(_ topic: ReaderAbstractTopic) {
        titleLabel.text = topic.title.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
        followButton.isSelected = topic.following
        WPStyleGuide.applyTagsReaderButtonStyle(followButton)
    }

    // MARK: - Actions

    @IBAction func didTapFollowButton(_ sender: UIButton) {
        followButton.isUserInteractionEnabled = false

        delegate?.handleFollowActionForHeader(self, completion: { [weak self] in
            self?.followButton.isUserInteractionEnabled = true
        })
    }
}
