import UIKit
import WordPressShared

/// TableViewHeaderDetailView displays a title and detail using autolayout.
///
open class TableViewHeaderDetailView: UITableViewHeaderFooterView
{
    /// Title is displayed in standard section header style
    ///
    open var title: String = "" {
        didSet {
            if title != oldValue {
                titleLabel.text = title.uppercased(with: Locale.current)
                setNeedsLayout()
            }
        }
    }

    /// Detail is displayed in standard section footer style
    ///
    open var detail: String = "" {
        didSet {
            if detail != oldValue {
                detailLabel.text = detail
                setNeedsLayout()
            }
        }
    }

    /// layoutWidth may be set from heightForHeaderInSection then intrinsicSize queried for height
    ///
    open var layoutWidth: CGFloat = 0 {
        didSet {
            layoutWidth = Style.layoutWidthFitting(layoutWidth)
            if layoutWidth != oldValue {
                let labelWidth = max(layoutWidth - stackView.layoutMargins.left - stackView.layoutMargins.right, 0)
                titleLabel.preferredMaxLayoutWidth = labelWidth
                detailLabel.preferredMaxLayoutWidth = labelWidth

                stackWidthConstraint?.constant = layoutWidth
                setNeedsUpdateConstraints()
            }
        }
    }

    // MARK: - Private Aliases

    fileprivate typealias Style = WPStyleGuide.TableViewHeaderDetailView

    // MARK: - Private Properties

    fileprivate let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.font = Style.titleFont
        titleLabel.textColor = Style.titleColor

        return titleLabel
    }()

    fileprivate let detailLabel: UILabel = {
        let detailLabel = UILabel()
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.numberOfLines = 0
        detailLabel.lineBreakMode = .byWordWrapping
        detailLabel.font = Style.detailFont
        detailLabel.textColor = Style.detailColor

        return detailLabel
    }()

    fileprivate let stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = Style.headerDetailSpacing
        stackView.layoutMargins = Style.layoutMargins
        stackView.isLayoutMarginsRelativeArrangement = true

        return stackView
    }()

    fileprivate var stackWidthConstraint: NSLayoutConstraint?

    // MARK: - Initializers

    /// Convenience initializer for TableViewHeaderDetailView
    ///
    /// - Parameters:
    ///     - title: String displayed in standard section header style
    ///     - detail: String displayed in standard section footer style
    ///
    convenience public init(title: String?, detail: String?) {
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

    required public init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        stackSubviews()
    }

    fileprivate func stackSubviews() {
        contentView.addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(detailLabel)

        stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        stackWidthConstraint = stackView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width)
        stackWidthConstraint?.isActive = true
    }

    // MARK: - View Lifecycle

    override open func layoutSubviews() {
        super.layoutSubviews()

        layoutWidth = frame.size.width
    }

    override open var intrinsicContentSize: CGSize {
        guard layoutWidth > 0 else {
            return CGSize.zero
        }

        let titleSize = titleLabel.intrinsicContentSize
        let detailSize = detailLabel.intrinsicContentSize
        let height = stackView.layoutMargins.top + titleSize.height + stackView.spacing + detailSize.height + stackView.layoutMargins.bottom

        return CGSize(width: layoutWidth, height: height)
    }

    override open func prepareForReuse() {
        super.prepareForReuse()

        title = ""
        detail = ""
    }
}

/// WPStyleGuide extension with styles and methods specific to TableViewHeaderDetailView.
///
extension WPStyleGuide
{
    public struct TableViewHeaderDetailView
    {
        // MARK: - Text Styles

        public static let titleFont = WPStyleGuide.tableviewSectionHeaderFont()
        public static let titleColor = WPStyleGuide.greyDarken20()

        public static let detailFont = WPStyleGuide.tableviewSectionHeaderFont()
        public static let detailColor = WPStyleGuide.greyDarken10()

        // MARK: - Metrics

        public static func layoutWidthFitting(_ width: CGFloat) -> CGFloat {
            var result = max(width, sideMargin * 2)
            if UIDevice.isPad() {
                result = min(result, WPTableViewFixedWidth)
            }
            return result
        }

        public static let topMargin: CGFloat = 21
        public static let bottomMargin: CGFloat = 8
        public static let sideMargin: CGFloat = 16
        public static let layoutMargins = UIEdgeInsets(top: topMargin, left: sideMargin, bottom: bottomMargin, right: sideMargin)

        public static let headerDetailSpacing: CGFloat = 8
    }
}
