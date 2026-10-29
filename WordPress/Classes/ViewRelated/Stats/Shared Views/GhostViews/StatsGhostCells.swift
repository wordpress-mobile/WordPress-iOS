import UIKit
import WordPressKit
import WordPressShared

class StatsGhostBaseCell: StatsBaseCell {
    private typealias Style = WPStyleGuide.Stats
    private(set) var topBorder: UIView?
    private(set) var bottomBorder: UIView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        headingLabel.isGhostableDisabled = true
        Style.configureCell(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        // Restart animation when toggling light/dark mode so colors are updated.
        restartGhostAnimation(style: GhostCellStyle.muriel)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopGhostAnimation()
    }
}

/// A placeholder view for the ghost animation, optionally with a fixed size.
private func makeGhostView(width: CGFloat? = nil, height: CGFloat? = nil, minimumWidth: CGFloat? = nil) -> UIView {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    if let width {
        view.widthAnchor.constraint(equalToConstant: width).isActive = true
    }
    if let minimumWidth {
        view.widthAnchor.constraint(greaterThanOrEqualToConstant: minimumWidth).isActive = true
    }
    if let height {
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
    }
    return view
}

private func makeGhostStackView(
    _ axis: NSLayoutConstraint.Axis,
    distribution: UIStackView.Distribution = .fill,
    alignment: UIStackView.Alignment = .fill,
    spacing: CGFloat = 0,
    arrangedSubviews: [UIView]
) -> UIStackView {
    let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = axis
    stackView.distribution = distribution
    stackView.alignment = alignment
    stackView.spacing = spacing
    return stackView
}

class StatsGhostGrowAudienceCell: StatsGhostBaseCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        clipsToBounds = true
        contentView.clipsToBounds = true

        let title = makeGhostView(width: 200, height: 16)
        let subtitle = makeGhostView(width: 175, height: 32)
        let lines = makeGhostStackView(
            .vertical,
            spacing: 12,
            arrangedSubviews: [
                makeGhostView(height: 16),
                makeGhostView(height: 16)
            ]
        )
        let buttons = makeGhostStackView(
            .horizontal,
            distribution: .equalSpacing,
            spacing: 16,
            arrangedSubviews: [
                makeGhostView(width: 100),
                makeGhostView(width: 100)
            ]
        )
        [title, subtitle, lines, buttons].forEach(contentView.addSubview)

        let topConstraint = title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40)
        NSLayoutConstraint.activate([
            topConstraint,
            title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 32),
            subtitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            lines.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 12),
            lines.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            lines.widthAnchor.constraint(equalToConstant: 250),

            buttons.topAnchor.constraint(equalTo: lines.bottomAnchor, constant: 48),
            buttons.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: buttons.trailingAnchor, constant: 16),
            buttons.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            buttons.heightAnchor.constraint(equalToConstant: 16),
            contentView.bottomAnchor.constraint(equalTo: buttons.bottomAnchor, constant: 16)
        ])
        self.topConstraint = topConstraint
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class StatsGhostTwoColumnCell: StatsGhostBaseCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.clipsToBounds = true
        selectionStyle = .none

        let separator = makeGhostView(width: 1)
        let leftTitle = makeGhostView(height: 17)
        let leftValue = makeGhostView(height: 31)
        let rightTitle = makeGhostView(height: 17)
        let rightValue = makeGhostView(height: 31)
        [separator, leftTitle, leftValue, rightTitle, rightValue].forEach(contentView.addSubview)

        let topConstraint = leftTitle.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 13)
        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 13),
            contentView.bottomAnchor.constraint(equalTo: separator.bottomAnchor, constant: 13),
            separator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            topConstraint,
            leftTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separator.leadingAnchor.constraint(equalTo: leftTitle.trailingAnchor, constant: 16),
            leftValue.topAnchor.constraint(equalTo: leftTitle.bottomAnchor, constant: 5),
            leftValue.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separator.leadingAnchor.constraint(equalTo: leftValue.trailingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: leftValue.bottomAnchor, constant: 13),

            rightTitle.topAnchor.constraint(equalTo: leftTitle.topAnchor),
            rightTitle.leadingAnchor.constraint(equalTo: separator.trailingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: rightTitle.trailingAnchor, constant: 16),
            rightValue.topAnchor.constraint(equalTo: rightTitle.bottomAnchor, constant: 5),
            rightValue.leadingAnchor.constraint(equalTo: separator.trailingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: rightValue.trailingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: rightValue.bottomAnchor, constant: 13)
        ])
        self.topConstraint = topConstraint
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class StatsGhostTopHeaderCell: StatsGhostBaseCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        clipsToBounds = true
        contentView.clipsToBounds = true

        let leading = makeGhostView(width: 50, height: 16)
        let trailing = makeGhostView(width: 50, height: 16)
        [leading, trailing].forEach(contentView.addSubview)

        let topConstraint = leading.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7)
        NSLayoutConstraint.activate([
            topConstraint,
            leading.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: leading.bottomAnchor, constant: 16),

            trailing.topAnchor.constraint(equalTo: leading.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailing.trailingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: trailing.bottomAnchor, constant: 16)
        ])
        self.topConstraint = topConstraint
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class StatsGhostChartCell: StatsGhostBaseCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        clipsToBounds = true
        contentView.clipsToBounds = true
        selectionStyle = .none

        let value = makeGhostView(width: 20, height: 38)
        let difference = makeGhostView(width: 45, height: 20)
        let bars = makeGhostStackView(
            .horizontal,
            distribution: .fillEqually,
            spacing: 7,
            arrangedSubviews: (0..<13).map { _ in makeGhostView(minimumWidth: 10) }
        )
        let axisLabels = makeGhostStackView(
            .vertical,
            distribution: .equalSpacing,
            arrangedSubviews: (0..<5).map { _ in makeGhostView(width: 16, height: 8) }
        )
        let leadingLegend = makeGhostView(width: 65, height: 8)
        let trailingLegend = makeGhostView(width: 65, height: 8)
        [value, difference, bars, leadingLegend, trailingLegend, axisLabels].forEach(contentView.addSubview)

        let topConstraint = value.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 25)
        NSLayoutConstraint.activate([
            topConstraint,
            value.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            difference.leadingAnchor.constraint(equalTo: value.trailingAnchor, constant: 8),
            difference.bottomAnchor.constraint(equalTo: value.bottomAnchor),

            bars.topAnchor.constraint(equalTo: value.bottomAnchor, constant: 16),
            bars.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            contentView.trailingAnchor.constraint(equalTo: bars.trailingAnchor, constant: 16),
            bars.heightAnchor.constraint(equalToConstant: 100),

            axisLabels.topAnchor.constraint(equalTo: value.bottomAnchor, constant: 16),
            axisLabels.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            axisLabels.widthAnchor.constraint(equalToConstant: 16),
            axisLabels.heightAnchor.constraint(equalToConstant: 100),

            leadingLegend.topAnchor.constraint(equalTo: bars.bottomAnchor, constant: 8),
            leadingLegend.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: leadingLegend.bottomAnchor, constant: 25),

            trailingLegend.topAnchor.constraint(equalTo: bars.bottomAnchor, constant: 8),
            contentView.trailingAnchor.constraint(equalTo: trailingLegend.trailingAnchor, constant: 16)
        ])
        self.topConstraint = topConstraint
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class StatsGhostTabbedCell: StatsGhostBaseCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        clipsToBounds = true
        contentView.clipsToBounds = true
        selectionStyle = .none

        let tabs = makeGhostStackView(
            .horizontal,
            distribution: .fillEqually,
            alignment: .center,
            spacing: 80,
            arrangedSubviews: [makeGhostView(height: 18), makeGhostView(height: 18)]
        )
        tabs.layoutMargins = UIEdgeInsets(top: 13, left: 40, bottom: 13, right: 40)
        tabs.isLayoutMarginsRelativeArrangement = true
        let selectedTabIndicator = makeGhostView(height: 2)
        let leadingHeader = makeGhostView(width: 50, height: 16)
        let trailingHeader = makeGhostView(width: 50, height: 16)
        let icon = makeGhostView(width: 28, height: 28)
        let label = makeGhostView(height: 16)
        [tabs, selectedTabIndicator, trailingHeader, leadingHeader, icon, label].forEach(contentView.addSubview)

        let topConstraint = tabs.topAnchor.constraint(equalTo: contentView.topAnchor)
        NSLayoutConstraint.activate([
            topConstraint,
            tabs.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: tabs.trailingAnchor),
            tabs.heightAnchor.constraint(equalToConstant: 44),

            selectedTabIndicator.topAnchor.constraint(equalTo: tabs.bottomAnchor),
            selectedTabIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            // The indicator covers the first tab: contentView.trailing == indicator.trailing * 2
            NSLayoutConstraint(
                item: contentView,
                attribute: .trailing,
                relatedBy: .equal,
                toItem: selectedTabIndicator,
                attribute: .trailing,
                multiplier: 2,
                constant: 0
            ),

            leadingHeader.topAnchor.constraint(equalTo: selectedTabIndicator.bottomAnchor, constant: 7),
            leadingHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            trailingHeader.topAnchor.constraint(equalTo: selectedTabIndicator.bottomAnchor, constant: 7),
            contentView.trailingAnchor.constraint(equalTo: trailingHeader.trailingAnchor, constant: 16),

            icon.topAnchor.constraint(equalTo: leadingHeader.bottomAnchor, constant: 16),
            icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: icon.bottomAnchor, constant: 16),

            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            contentView.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 16)
        ])
        self.topConstraint = topConstraint
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class StatsGhostTitleCell: StatsGhostBaseCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        clipsToBounds = true
        contentView.clipsToBounds = true

        let title = makeGhostView(height: 16)
        let value = makeGhostView(height: 24)
        [title, value].forEach(contentView.addSubview)

        let topConstraint = title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16)
        NSLayoutConstraint.activate([
            topConstraint,
            title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: title.trailingAnchor, constant: 16),

            value.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            value.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: value.trailingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: value.bottomAnchor, constant: 16)
        ])
        self.topConstraint = topConstraint
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class StatsGhostSingleRowCell: StatsGhostBaseCell {
    private let border: UIView = {
        let border = makeGhostView()
        border.makeHairlineConstraint(for: border.heightAnchor).isActive = true
        border.backgroundColor = .separator
        border.isGhostableDisabled = true
        return border
    }()

    private var imageTopConstraint: NSLayoutConstraint!
    private var labelTopConstraint: NSLayoutConstraint!
    private var borderLeadingConstraint: NSLayoutConstraint!

    var enableTopPadding: Bool = false {
        didSet {
            imageTopConstraint.isActive = !enableTopPadding
            labelTopConstraint.isActive = !enableTopPadding
        }
    }

    var isLastRow: Bool = false {
        didSet {
            borderLeadingConstraint.isActive = isLastRow
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        clipsToBounds = true
        contentView.clipsToBounds = true

        let image = makeGhostView(width: 28, height: 28)
        let title = makeGhostView(height: 20)
        let subtitle = makeGhostView(height: 15)
        [image, title, subtitle, border].forEach(contentView.addSubview)

        imageTopConstraint = image.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8)
        labelTopConstraint = title.topAnchor.constraint(equalTo: contentView.topAnchor)
        borderLeadingConstraint = border.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)

        let topConstraint = image.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24)
        topConstraint.priority = UILayoutPriority(999)
        let paddedTitleTopConstraint = title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16)
        paddedTitleTopConstraint.priority = UILayoutPriority(999)
        let insetBorderLeadingConstraint = border.leadingAnchor.constraint(
            equalTo: contentView.leadingAnchor,
            constant: 60
        )
        insetBorderLeadingConstraint.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([
            imageTopConstraint,
            topConstraint,
            image.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            labelTopConstraint,
            paddedTitleTopConstraint,
            title.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: title.trailingAnchor, constant: 16),

            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 5),
            subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            subtitle.trailingAnchor.constraint(equalTo: title.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 16),

            borderLeadingConstraint,
            insetBorderLeadingConstraint,
            contentView.trailingAnchor.constraint(equalTo: border.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: border.bottomAnchor)
        ])
        self.topConstraint = topConstraint
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class StatsGhostPostingActivityCell: StatsGhostBaseCell {
    private var monthData: [PostingStreakEvent] = {
        Date().getAllDays().map { PostingStreakEvent(date: $0, postCount: 0) }
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        clipsToBounds = true
        contentView.clipsToBounds = true
        selectionStyle = .none

        let months = makeGhostStackView(.horizontal, distribution: .fillEqually, spacing: 12, arrangedSubviews: [])
        for _ in 0...2 {
            let monthView = PostingActivityMonth()
            monthView.configureGhost(monthData: monthData)
            months.addArrangedSubview(monthView)
        }
        let legend = makeGhostView(height: 16)
        [months, legend].forEach(contentView.addSubview)

        let topConstraint = months.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8)
        NSLayoutConstraint.activate([
            topConstraint,
            months.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: months.trailingAnchor, constant: 16),
            months.heightAnchor.constraint(equalToConstant: 135),

            legend.topAnchor.constraint(equalTo: months.bottomAnchor, constant: 16),
            legend.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            // The legend spans 40% of the cell: contentView.trailing == legend.trailing * 2.5
            NSLayoutConstraint(
                item: contentView,
                attribute: .trailing,
                relatedBy: .equal,
                toItem: legend,
                attribute: .trailing,
                multiplier: 2.5,
                constant: 0
            ),
            contentView.bottomAnchor.constraint(equalTo: legend.bottomAnchor, constant: 16)
        ])
        self.topConstraint = topConstraint
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate extension Date {
    mutating func add(days: Int) {
        self = Calendar.current.date(byAdding: .day, value: days, to: self)!
    }

    func firstDayOfTheMonth() -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.month, .year], from: self)) ?? self
    }

    func getAllDays() -> [Date] {
        var days: [Date] = []
        let range = Calendar.current.range(of: .day, in: .month, for: self)!
        var day = firstDayOfTheMonth()

        for _ in 1...range.count {
            days.append(day)
            day.add(days: 1)
        }

        return days
    }
}
