
import UIKit

import Gridicons
import WordPressShared

// MARK: - InlineErrorRetryTableViewCellAccessoryView

/// The accessory view comprises a retry Gridicon & advisory text
///
private class InlineErrorRetryTableViewCellAccessoryView: UIStackView {

    // MARK: Properties

    /// A collection of parameters uses for view layout
    private struct Metrics {
        static let minimumHeight    = CGFloat(28)
        static let retryDimension   = CGFloat(16)
        static let padding          = CGFloat(4)
    }

    /// One of the arranged subviews : a "refresh" Gridicon
    private let retryImageView: UIImageView

    /// One of the arranged subviews : user-facing text
    private let retryLabel: UILabel

    // MARK: InlineErrorRetryTableViewCellAccessoryView

    init() {
        self.retryImageView = {
            let dismissImage = UIImage.gridicon(.refresh).imageWithTintColor(.primary)
            let imageView = UIImageView(image: dismissImage)

            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit

            return imageView
        }()

        self.retryLabel = {
            let label = UILabel()

            label.translatesAutoresizingMaskIntoConstraints = false

            label.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .bold)
            label.textColor = .primary
            label.textAlignment = .center

            label.text = NSLocalizedString("Retry", comment: "Title for accessory view in the empty state table view cell in the Verticals step of Enhanced Site Creation")
            label.sizeToFit()

            return label
        }()

        super.init(frame: .zero)

        initialize()
    }

    // MARK: UIView

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private behavior

    private func initialize() {
        translatesAutoresizingMaskIntoConstraints = false

        axis = .horizontal
        alignment = .center
        spacing = Metrics.padding

        addArrangedSubviews([retryImageView, retryLabel])

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: Metrics.minimumHeight),
            retryImageView.widthAnchor.constraint(equalToConstant: Metrics.retryDimension),
            retryImageView.heightAnchor.constraint(equalToConstant: Metrics.retryDimension),
        ])
    }
}

// MARK: - InlineErrorRetryTableViewCell

/// Responsible for apprising the user of an error that occurred, accompanied by a visual affordance to retry the preceding action.
///
final class InlineErrorRetryTableViewCell: UITableViewCell, ReusableCell {

    // MARK: Properties

    /// A collection of parameters uses for view layout
    private struct Metrics {
        static let height           = CGFloat(44)
        static let trailingInset    = CGFloat(16)
    }

    /// A subview akin to an accessory view
    private let retryAccessoryView = InlineErrorRetryTableViewCellAccessoryView()

    // MARK: UITableViewCell

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: InlineErrorRetryTableViewCell.cellReuseIdentifier())
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal behavior

    func setMessage(_ message: String) {
        textLabel?.text = message
    }

    // MARK: Private behavior

    private func initialize() {
        if let label = textLabel {
            WPStyleGuide.configureLabel(label, textStyle: .body)
            label.textColor = .neutral(.shade40)
        }

        let borderColor = UIColor.neutral(.shade10)
        addTopBorder(withColor: borderColor)
        addBottomBorder(withColor: borderColor)

        accessoryType = .none

        addSubview(retryAccessoryView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Metrics.height),
            retryAccessoryView.centerYAnchor.constraint(equalTo: centerYAnchor),
            retryAccessoryView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.trailingInset)
        ])
    }
}
