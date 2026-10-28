import UIKit
import WordPressShared

class StatsChildRowsView: UIView {

    // MARK: - Properties

    let rowsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    let bottomSeperatorLine = UIView.makeStatsSeparator()

    var showBottomSeperatorLine = true {
        didSet {
            bottomSeperatorLine.isHidden = !showBottomSeperatorLine
        }
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        applyStatsXibRootDefaults(size: CGSize(width: 375, height: 219))

        backgroundColor = .secondarySystemGroupedBackground
        WPStyleGuide.Stats.configureViewAsSeparator(bottomSeperatorLine)

        addSubview(rowsStackView)
        addSubview(bottomSeperatorLine)

        let guide = safeAreaLayoutGuide
        let bottomConstraint = guide.bottomAnchor.constraint(equalTo: bottomSeperatorLine.bottomAnchor)
        bottomConstraint.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            rowsStackView.topAnchor.constraint(equalTo: guide.topAnchor),
            rowsStackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            guide.trailingAnchor.constraint(equalTo: rowsStackView.trailingAnchor),

            bottomSeperatorLine.topAnchor.constraint(equalTo: rowsStackView.bottomAnchor),
            guide.leadingAnchor.constraint(equalTo: bottomSeperatorLine.leadingAnchor),
            guide.trailingAnchor.constraint(equalTo: bottomSeperatorLine.trailingAnchor),
            bottomConstraint
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
