import Foundation
import UIKit
import WordPressShared
import WordPressUI

// MARK: - View Model

@objc public class MediaQuotaCell: UITableViewCell {

    @objc public static let height: Float = 66.0

    @objc public static let defaultReuseIdentifier = "MediaQuotaCell"

    // MARK: - Public interface
    @objc public var value: String? {
        get {
            valueLabel.text
        }
        set {
            valueLabel.text = newValue
        }
    }

    @objc public var title: String? {
        get {
            titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }

    @objc public var percentage: NSNumber? {
        get {
            NSNumber(value: progressView.progress)
        }
        set {
            if let nonNilValue = newValue {
                progressView.progress = nonNilValue.floatValue
            } else {
                progressView.progress = 0
            }
        }
    }

    // MARK: - Private properties

    @objc public func customizeAppearance() {
        titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        titleLabel.textColor = .label
        valueLabel.font = UIFont.preferredFont(forTextStyle: .callout)
        valueLabel.textColor = .secondaryLabel
        progressView.progressTintColor = UIAppColor.primary
        progressView.trackTintColor = .separator
    }

    // MARK: - Init

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        clipsToBounds = true
        contentView.isOpaque = false
        contentView.clipsToBounds = true
        contentView.contentMode = .center
        contentView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isOpaque = false
        stackView.distribution = .fillProportionally

        contentView.addSubview(stackView)
        contentView.addSubview(progressView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor, constant: 5),
            stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            progressView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 10),
            progressView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
        ])

        customizeAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc let titleLabel = makeLabel(textAlignment: .left)
    @objc let valueLabel = makeLabel(textAlignment: .right)
    @objc let progressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.isOpaque = false
        progressView.progress = 0.5
        progressView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return progressView
    }()

    private static func makeLabel(textAlignment: NSTextAlignment) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isOpaque = false
        label.backgroundColor = nil
        label.contentMode = .left
        label.textAlignment = textAlignment
        label.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)
        return label
    }
}
