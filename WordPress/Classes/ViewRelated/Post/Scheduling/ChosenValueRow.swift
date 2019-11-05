import Foundation

/// A view with a title and detail label similar to the detail table view cell
class ChosenValueRow: UIView {

    private struct Constants {
        static let rowHeight: CGFloat = 44
        static let rowInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }

    let titleLabel = UILabel()
    let detailLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        titleLabel.font = UIFont.preferredFont(forTextStyle: .callout)

        if effectiveUserInterfaceLayoutDirection == .leftToRight {
            // swiftlint:disable:next inverse_text_alignment
            detailLabel.textAlignment = .right
        } else {
            // swiftlint:disable:next natural_text_alignment
            detailLabel.textAlignment = .left
        }
        detailLabel.textColor = .textSubtle

        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            detailLabel
        ])
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)
        setupConstraints(stackView: stackView)
    }

    private func setupConstraints(stackView: UIView) {
        pinSubviewToAllEdges(stackView, insets: Constants.rowInsets)

        let heightConstraint = stackView.heightAnchor.constraint(equalToConstant: Constants.rowHeight)
        heightConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            heightConstraint
        ])
    }
}
