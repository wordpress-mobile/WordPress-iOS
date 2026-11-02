import UIKit
import WordPressShared

class PostingActivityLegend: UIView {

    // MARK: - Properties

    private let fewerPostsLabel = UILabel.makeStatsLabel(text: "Fewer Posts", textStyle: .footnote)
    private let morePostsLabel = UILabel.makeStatsLabel(text: "More Posts", textStyle: .footnote)

    private let colorsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillEqually
        stackView.spacing = 5
        return stackView
    }()

    private typealias Style = WPStyleGuide.Stats

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        applyStatsXibRootDefaults(size: CGSize(width: 375, height: 44))

        let stackView = UIStackView(arrangedSubviews: [fewerPostsLabel, colorsStackView, morePostsLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 10

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        addSubview(contentView)

        let guide = safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: guide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(greaterThanOrEqualTo: stackView.trailingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 12),

            morePostsLabel.widthAnchor.constraint(equalTo: fewerPostsLabel.widthAnchor),
            colorsStackView.widthAnchor.constraint(equalToConstant: 80)
        ])

        applyStyles()
        addColors()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Class Methods

    static func colorForCount(_ count: Int) -> UIColor? {
        switch count {
        case 0:
            return Style.PostingActivityColors.range1
        case 1...2:
            return Style.PostingActivityColors.range2
        case 3...5:
            return Style.PostingActivityColors.range3
        case 6...7:
            return Style.PostingActivityColors.range4
        default:
            return Style.PostingActivityColors.range5
        }
    }
}

// MARK: - Private Extension

private extension PostingActivityLegend {

    func applyStyles() {
        fewerPostsLabel.text = NSLocalizedString("Fewer Posts", comment: "Label for the posting activity legend.")
        morePostsLabel.text = NSLocalizedString("More Posts", comment: "Label for the posting activity legend.")
        Style.configureLabelAsPostingLegend(fewerPostsLabel)
        Style.configureLabelAsPostingLegend(morePostsLabel)
    }

    func addColors() {
        var numberInRange = 0
        for _ in 1...5 {
            let dayView = PostingActivityDay()
            dayView.configure()
            dayView.dayButton.backgroundColor = PostingActivityLegend.colorForCount(numberInRange)
            colorsStackView.addArrangedSubview(dayView)
            numberInRange += 2
        }
    }
}
