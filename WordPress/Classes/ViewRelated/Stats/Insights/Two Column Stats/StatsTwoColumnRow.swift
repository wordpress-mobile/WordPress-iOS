import UIKit
import DesignSystem
import WordPressShared

struct StatsTwoColumnRowData: Equatable {
    var leftColumnName: String
    var leftColumnData: String
    var rightColumnName: String
    var rightColumnData: String

    init(
        leftColumnName: String,
        leftColumnData: String,
        rightColumnName: String,
        rightColumnData: String
    ) {
        self.leftColumnName = leftColumnName
        self.leftColumnData = leftColumnData
        self.rightColumnName = rightColumnName
        self.rightColumnData = rightColumnData
    }
}

class StatsTwoColumnRow: UIView, Accessible {

    // MARK: - Properties

    private let leftItemLabel = UILabel.makeStatsLabel(text: "Item Label", textStyle: .subheadline)
    private let leftDataLabel = makeDataLabel()
    private let separatorLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.667, alpha: 1)
        return view
    }()
    private let rightItemLabel = UILabel.makeStatsLabel(text: "Item Label", textStyle: .subheadline)
    private let rightDataLabel = makeDataLabel()

    private typealias Style = WPStyleGuide.Stats

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        applyStatsXibRootDefaults(
            size: CGSize(width: 442, height: 80),
            mask: [.flexibleRightMargin, .flexibleBottomMargin]
        )

        backgroundColor = .clear

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear
        [leftItemLabel, leftDataLabel, separatorLine, rightItemLabel, rightDataLabel].forEach(contentView.addSubview)
        addSubview(contentView)

        let guide = safeAreaLayoutGuide
        let bottomConstraint = guide.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        bottomConstraint.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: guide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            guide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 16),
            bottomConstraint,

            separatorLine.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: separatorLine.bottomAnchor),
            separatorLine.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            separatorLine.widthAnchor.constraint(equalToConstant: 1),

            leftItemLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            leftItemLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: leftItemLabel.trailingAnchor, constant: 16),
            leftDataLabel.topAnchor.constraint(equalTo: leftItemLabel.bottomAnchor),
            leftDataLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: leftDataLabel.trailingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: leftDataLabel.bottomAnchor),

            rightItemLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            rightItemLabel.leadingAnchor.constraint(equalTo: separatorLine.trailingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: rightItemLabel.trailingAnchor),
            rightDataLabel.topAnchor.constraint(equalTo: rightItemLabel.bottomAnchor),
            rightDataLabel.leadingAnchor.constraint(equalTo: separatorLine.trailingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: rightDataLabel.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: rightDataLabel.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeDataLabel() -> UILabel {
        let label = UILabel.makeStatsLabel(text: "9,999", textStyle: .title1)
        label.setContentCompressionResistancePriority(UILayoutPriority(751), for: .vertical)
        return label
    }

    // MARK: - Configure

    func configure(rowData: StatsTwoColumnRowData) {
        leftItemLabel.text = rowData.leftColumnName
        leftDataLabel.text = rowData.leftColumnData
        rightItemLabel.text = rowData.rightColumnName
        rightDataLabel.text = rowData.rightColumnData

        leftDataLabel.accessibilityLabel = rowData.leftColumnData.accessibilityLabel
        rightDataLabel.accessibilityLabel = rowData.rightColumnData.accessibilityLabel

        applyStyles()
        prepareForVoiceOver()
    }

    func prepareForVoiceOver() {
        accessibilityElements = [leftItemLabel, leftDataLabel, rightItemLabel, rightDataLabel].compactMap { $0 }
    }
}

// MARK: - Private Extension

private extension StatsTwoColumnRow {

    func applyStyles() {
        Style.configureLabelAsCellValueTitle(leftItemLabel)
        Style.configureLabelAsCellValue(leftDataLabel)
        Style.configureLabelAsCellValueTitle(rightItemLabel)
        Style.configureLabelAsCellValue(rightDataLabel)
        Style.configureViewAsVerticalSeparator(separatorLine)
    }
}
