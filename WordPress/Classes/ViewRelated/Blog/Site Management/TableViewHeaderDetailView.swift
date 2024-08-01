import UIKit
import WordPressShared

/// TableViewHeaderDetailView displays a title and detail using autolayout.
///
open class TableViewHeaderDetailView: UITableViewHeaderFooterView {
    /// Title is displayed in standard section header style
    ///
    @objc open var title: String = "" {
        didSet {
            if title != oldValue {
                titleLabel.text = title.localizedUppercase
                setNeedsLayout()
            }
        }
    }

    /// Detail is displayed in standard section footer style
    ///
    @objc open var detail: String = "" {
        didSet {
            if detail != oldValue {
                detailLabel.text = detail
                setNeedsLayout()
            }
        }
    }

    // MARK: - Private Properties

    fileprivate let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label

        return titleLabel
    }()

    fileprivate let detailLabel: UILabel = {
        let detailLabel = UILabel()
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.numberOfLines = 0
        detailLabel.lineBreakMode = .byWordWrapping
        detailLabel.font = .preferredFont(forTextStyle: .subheadline)
        detailLabel.textColor = .secondaryLabel

        return detailLabel
    }()

    fileprivate let stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 8

        return stackView
    }()

    // MARK: - Initializers

    /// Convenience initializer for TableViewHeaderDetailView
    ///
    /// - Parameters:
    ///     - title: String displayed in standard section header style
    ///     - detail: String displayed in standard section footer style
    ///
    @objc convenience public init(title: String?, detail: String?) {
        self.init(reuseIdentifier: nil)
        defer {
            self.title = title ?? ""
            self.detail = detail ?? ""
        }
    }

    override public init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        stackSubviews()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        stackSubviews()
    }

    fileprivate func stackSubviews() {

        contentView.addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(detailLabel)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.readableContentGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.readableContentGuide.bottomAnchor),
            ])
    }

    // MARK: - View Lifecycle

    override open func prepareForReuse() {
        super.prepareForReuse()

        title = ""
        detail = ""
    }
}
