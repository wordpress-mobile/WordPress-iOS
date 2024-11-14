import SwiftUI
import UIKit
import WordPressUI

final class ReaderRecommendedTagsCell: UITableViewCell {
    private let scrollView = UIScrollView()
    private let tagsStackView = UIStackView(axis: .horizontal, spacing: 8, insets: UIEdgeInsets(.vertical, 16), [])

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        for view in tagsStackView.subviews {
            view.removeFromSuperview()
        }
    }

    private func setupView() {
        selectionStyle = .none

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = false

        let backgroundView = UIView()
        backgroundView.backgroundColor = .secondarySystemBackground
        backgroundView.layer.cornerRadius = 8
        backgroundView.clipsToBounds = true

        contentView.addSubview(backgroundView)
        backgroundView.pinEdges(insets: UIEdgeInsets(.all, 16))

        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleLabel.textColor = .secondaryLabel
        titleLabel.text = Strings.title

        let stackView = UIStackView(axis: .vertical, [titleLabel, scrollView])

        scrollView.addSubview(tagsStackView)
        tagsStackView.pinEdges()
        scrollView.heightAnchor.constraint(equalTo: tagsStackView.heightAnchor).isActive = true

        backgroundView.addSubview(stackView)
        stackView.pinEdges(insets: {
            var insets = UIEdgeInsets(.all, 16)
            insets.bottom = 6 // Covered by the scroll view
            return insets
        }())
    }

    func configure(with topics: [ReaderTagTopic], delegate: ReaderRecommendationsCellDelegate) {
        for topic in topics {
            var configuration = UIButton.Configuration.borderedTinted()
            configuration.title = topic.title
            configuration.cornerStyle = .capsule
            configuration.baseForegroundColor = .label
            configuration.titleTextAttributesTransformer = .init {
                var container = $0
                container.font = UIFont.preferredFont(forTextStyle: .subheadline).withWeight(.medium)
                return container
            }
            configuration.baseBackgroundColor = .secondaryLabel

            let button = UIButton(configuration: configuration)
            button.addAction(.init(handler: { [weak delegate] _ in
                delegate?.didSelect(topic: topic)
            }), for: .primaryActionTriggered)

            tagsStackView.addArrangedSubview(button)
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString("reader.suggested.tags.title", value: "You might like", comment: "A suggestion of topics (tags) the user might like")
}
