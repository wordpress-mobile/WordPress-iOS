
import UIKit

import Gridicons
import WordPressShared

// MARK: - VerticalErrorRetryTableViewCellAccessoryView

/// The accessory view comprises a retry Gridicon
private class VerticalErrorRetryTableViewCellAccessoryView: UIStackView {

    // MARK: Properties

    /// A collection of parameters uses for view layout
    private struct Parameters {
        static let minimumHeight    = CGFloat(28)
        static let retryDimension   = CGFloat(16)
        static let padding          = CGFloat(4)
    }

    /// One of the arranged subviews : a "refresh" Gridicon
    private let retryImageView: UIImageView

    /// One of the arranged subviews : user-facing text
    private let retryLabel: UILabel

    // MARK: VerticalErrorRetryTableViewCellAccessoryView

    init() {
        self.retryImageView = {
            let dismissImage = Gridicon.iconOfType(.refresh).imageWithTintColor(WPStyleGuide.wordPressBlue())
            let imageView = UIImageView(image: dismissImage)

            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit

            return imageView
        }()

        self.retryLabel = {
            let label = UILabel()

            label.translatesAutoresizingMaskIntoConstraints = false

            label.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .bold)
            label.textColor = WPStyleGuide.wordPressBlue()
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
        spacing = Parameters.padding

        addArrangedSubviews([retryImageView, retryLabel])

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: Parameters.minimumHeight),
            retryImageView.widthAnchor.constraint(equalToConstant: Parameters.retryDimension),
            retryImageView.heightAnchor.constraint(equalToConstant: Parameters.retryDimension),
        ])
    }
}

// MARK: - VerticalErrorRetryTableViewCell

/// Responsible for apprising the user of an error that occurred, accompanied by a visual affordance to retry the
/// preceding action.
///
final class VerticalErrorRetryTableViewCell: UITableViewCell, ReusableCell {

    // MARK: Properties

    /// A collection of parameters uses for view layout
    private struct Parameters {
        static let height           = CGFloat(44)
        static let trailingInset    = CGFloat(16)
    }

    /// A subview akin to an accessory view
    private let retryAccessoryView = VerticalErrorRetryTableViewCellAccessoryView()

    // MARK: UITableViewCell

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: VerticalErrorRetryTableViewCell.cellReuseIdentifier())
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal behavior

    func setMessage(_ message: EmptyVerticalsMessage) {
        textLabel?.text = message
    }

    // MARK: Private behavior

    private func initialize() {
        if let label = textLabel {
            WPStyleGuide.configureLabel(label, textStyle: .body)
            label.textColor = WPStyleGuide.greyDarken10()
        }

        let borderColor = WPStyleGuide.greyLighten20()
        addTopBorder(withColor: borderColor)
        addBottomBorder(withColor: borderColor)

        accessoryType = .none

        addSubview(retryAccessoryView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Parameters.height),
            retryAccessoryView.centerYAnchor.constraint(equalTo: centerYAnchor),
            retryAccessoryView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Parameters.trailingInset)
        ])
    }
}
