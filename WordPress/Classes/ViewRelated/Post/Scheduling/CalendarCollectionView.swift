import Foundation
import JTAppleCalendar

enum CalendarCollectionViewStyle {
    case month
    case year
}

class CalendarCollectionView: WPJTACMonthView {

    let calDataSource: CalendarDataSource
    let style: CalendarCollectionViewStyle

    init(calendar: Calendar,
         style: CalendarCollectionViewStyle = .month,
         startDate: Date? = nil,
         endDate: Date? = nil) {
        calDataSource = CalendarDataSource(
            calendar: calendar,
            style: style,
            startDate: startDate,
            endDate: endDate
        )

        self.style = style
        super.init()

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        calDataSource = CalendarDataSource(calendar: Calendar.current, style: .month)
        style = .month
        super.init(coder: aDecoder)

        setup()
    }

    private func setup() {
        register(DateCell.self, forCellWithReuseIdentifier: DateCell.Constants.reuseIdentifier)
        register(CalendarYearHeaderView.self,
                              forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                              withReuseIdentifier: CalendarYearHeaderView.reuseIdentifier)

        backgroundColor = .clear

        switch style {
        case .month:
            scrollDirection = .horizontal
            scrollingMode = .stopAtEachCalendarFrame
        case .year:
            scrollDirection = .vertical

            allowsMultipleSelection = true
            allowsRangedSelection = true
            rangeSelectionMode = .continuous

            minimumLineSpacing = 0
            minimumInteritemSpacing = 0

            cellSize = 50
        }

        showsHorizontalScrollIndicator = false
        isDirectionalLockEnabled = true

        calendarDataSource = calDataSource
        calendarDelegate = calDataSource
    }
}

class CalendarDataSource: JTACMonthViewDataSource {

    var willScroll: ((DateSegmentInfo) -> Void)?
    var didScroll: ((DateSegmentInfo) -> Void)?
    var didSelect: ((Date?, Date?) -> Void)?

    // First selected date
    var firstDate: Date?

    // End selected date
    var endDate: Date?

    private let calendar: Calendar
    private let style: CalendarCollectionViewStyle

    init(calendar: Calendar,
         style: CalendarCollectionViewStyle,
         startDate: Date? = nil,
         endDate: Date? = nil) {
        self.calendar = calendar
        self.style = style
        self.firstDate = startDate
        self.endDate = endDate
    }

    func configureCalendar(_ calendar: JTACMonthView) -> ConfigurationParameters {
        /// When style is year, display the last 20 years til this month
        if style == .year {
            var dateComponent = DateComponents()
            dateComponent.year = -20
            let startDate = Calendar.current.date(byAdding: dateComponent, to: Date())
            let endDate = Date().endOfMonth

            if let startDate = startDate, let endDate = endDate {
                return ConfigurationParameters(startDate: startDate, endDate: endDate, calendar: self.calendar)
            }
        }

        let startDate = Date.farPastDate
        let endDate = Date.farFutureDate
        return ConfigurationParameters(startDate: startDate, endDate: endDate, calendar: self.calendar)
    }
}

extension CalendarDataSource: JTACMonthViewDelegate {
    func calendar(_ calendar: JTACMonthView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTACDayCell {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: DateCell.Constants.reuseIdentifier, for: indexPath)
        if let dateCell = cell as? DateCell {
            configure(cell: dateCell, with: cellState)
        }
        return cell
    }

    func calendar(_ calendar: JTACMonthView, willDisplay cell: JTACDayCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        configure(cell: cell, with: cellState)
    }

    func calendar(_ calendar: JTACMonthView, willScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        willScroll?(visibleDates)
    }

    func calendar(_ calendar: JTACMonthView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        didScroll?(visibleDates)
    }

    func calendar(_ calendar: JTACMonthView, didSelectDate date: Date, cell: JTACDayCell?, cellState: CellState, indexPath: IndexPath) {
        if style == .year {
            // If the date is in the future, bail out
            if date > Date() {
                return
            }

            if let firstDate = firstDate {
                if let endDate = endDate {
                    // When tapping a selected firstDate or endDate reset the rest
                    if date == firstDate || date == endDate {
                        self.firstDate = date
                        self.endDate = nil
                    // Increase the range at the left side
                    } else if date < firstDate {
                        self.firstDate = date
                    // Increase the range at the right side
                    } else {
                        self.endDate = date
                    }
                // When tapping a single selected date, deselect everything
                } else if date == firstDate {
                    self.firstDate = nil
                    self.endDate = nil
                // When selecting a second date
                } else {
                    self.firstDate = min(firstDate, date)
                    endDate = max(firstDate, date)
                }
            // When selecting the first date
            } else {
                firstDate = date
            }
        // Monthly calendar only selects a single date
        } else {
            firstDate = date
        }

        didSelect?(firstDate, endDate)
        UIView.performWithoutAnimation {
            calendar.reloadItems(at: calendar.indexPathsForVisibleItems)
        }

        configure(cell: cell, with: cellState)
    }

    func calendar(_ calendar: JTACMonthView, didDeselectDate date: Date, cell: JTACDayCell?, cellState: CellState, indexPath: IndexPath) {
        configure(cell: cell, with: cellState)
    }

    func calendarSizeForMonths(_ calendar: JTACMonthView?) -> MonthSize? {
        return style == .year ? MonthSize(defaultSize: 50) : nil
    }

    func calendar(_ calendar: JTACMonthView, headerViewForDateRange range: (start: Date, end: Date), at indexPath: IndexPath) -> JTACMonthReusableView {
        let date = range.start
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let header = calendar.dequeueReusableJTAppleSupplementaryView(withReuseIdentifier: CalendarYearHeaderView.reuseIdentifier, for: indexPath)
        (header as! CalendarYearHeaderView).titleLabel.text = formatter.string(from: date)
        return header
    }

    private func configure(cell: JTACDayCell?, with state: CellState) {
        let cell = cell as? DateCell
        cell?.configure(with: state, startDate: firstDate, endDate: endDate, hideInOutDates: style == .year)
    }
}

class DateCell: JTACDayCell {

    struct Constants {
        static let labelSize: CGFloat = 28
        static let reuseIdentifier = "dateCell"
        static var selectedColor: UIColor {
            UIColor(light: .primary(.shade5), dark: .primary(.shade90))
        }
    }

    let dateLabel = UILabel()
    let leftPlaceholder = UIView()
    let rightPlaceholder = UIView()

    let dateFormatter = DateFormatter()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.textAlignment = .center
        dateLabel.font = UIFont.preferredFont(forTextStyle: .callout)

        // Show circle behind text for selected day
        dateLabel.clipsToBounds = true
        dateLabel.layer.cornerRadius = Constants.labelSize/2

        addSubview(dateLabel)

        NSLayoutConstraint.activate([
            dateLabel.widthAnchor.constraint(equalToConstant: Constants.labelSize),
            dateLabel.heightAnchor.constraint(equalTo: dateLabel.widthAnchor),
            dateLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            dateLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])

        leftPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        rightPlaceholder.translatesAutoresizingMaskIntoConstraints = false

        addSubview(leftPlaceholder)
        addSubview(rightPlaceholder)

        NSLayoutConstraint.activate([
            leftPlaceholder.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6),
            leftPlaceholder.heightAnchor.constraint(equalTo: dateLabel.heightAnchor),
            leftPlaceholder.trailingAnchor.constraint(equalTo: centerXAnchor),
            leftPlaceholder.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        NSLayoutConstraint.activate([
            rightPlaceholder.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5),
            rightPlaceholder.heightAnchor.constraint(equalTo: dateLabel.heightAnchor),
            rightPlaceholder.leadingAnchor.constraint(equalTo: centerXAnchor, constant: 0),
            rightPlaceholder.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        bringSubviewToFront(dateLabel)
    }
}

extension DateCell {
    /// Configure the DateCell
    ///
    /// - Parameters:
    ///   - state: the representation of the cell state
    ///   - startDate: the first Date selected
    ///   - endDate: the last Date selected
    ///   - hideInOutDates: a Bool to hide/display dates outside of the current month (filling the entire row)
    /// - Returns: UIColor. Red in cases of error
    func configure(with state: CellState,
                   startDate: Date? = nil,
                   endDate: Date? = nil,
                   hideInOutDates: Bool = false) {

        dateLabel.text = state.text

        dateFormatter.setLocalizedDateFormatFromTemplate("MMM d, yyyy")
        dateLabel.accessibilityLabel = dateFormatter.string(from: state.date)
        dateLabel.accessibilityTraits = .button

        var textColor: UIColor

        if hideInOutDates && state.dateBelongsTo != .thisMonth {
            isHidden = true
        } else {
            isHidden = false
        }

        // Reset state
        leftPlaceholder.backgroundColor = .clear
        rightPlaceholder.backgroundColor = .clear
        dateLabel.backgroundColor = .clear
        textColor = .text

        switch position(for: state.date, startDate: startDate, endDate: endDate) {
        case .middle:
            textColor = .text
            leftPlaceholder.backgroundColor = Constants.selectedColor
            rightPlaceholder.backgroundColor = Constants.selectedColor
            dateLabel.backgroundColor = .clear
        case .left:
            textColor = .white
            dateLabel.backgroundColor = .primary
            rightPlaceholder.backgroundColor = Constants.selectedColor
        case .right:
            textColor = .white
            dateLabel.backgroundColor = .primary
            leftPlaceholder.backgroundColor = Constants.selectedColor
        case .full:
            textColor = .textInverted
            leftPlaceholder.backgroundColor = .clear
            rightPlaceholder.backgroundColor = .clear
            dateLabel.backgroundColor = .primary
        case .none:
            leftPlaceholder.backgroundColor = .clear
            rightPlaceholder.backgroundColor = .clear
            dateLabel.backgroundColor = .clear
            if state.date > Date() {
                textColor = .textSubtle
            } else if state.dateBelongsTo == .thisMonth {
              textColor = .text
            } else {
              textColor = .textSubtle
            }
        }

        dateLabel.textColor = textColor
    }

    func position(for date: Date, startDate: Date?, endDate: Date?) -> SelectionRangePosition {
        if let startDate = startDate, let endDate = endDate {
            if date == startDate {
                return .left
            } else if date == endDate {
                return .right
            } else if date > startDate && date < endDate {
                return .middle
            }
        } else if let startDate = startDate {
            if date == startDate {
                return .full
            }
        }

        return .none
    }
}

// MARK: - Year Header View
class CalendarYearHeaderView: JTACMonthReusableView {
    static let reuseIdentifier = "CalendarYearHeaderView"

    let titleLabel: UILabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Constants.stackViewSpacing

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToSafeArea(stackView)

        stackView.addArrangedSubview(titleLabel)
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center
        titleLabel.textColor = Constants.titleColor

        let weekdaysView = WeekdaysHeaderView(calendar: Calendar.current)
        stackView.addArrangedSubview(weekdaysView)

        stackView.setCustomSpacing(Constants.spacingAfterWeekdays, after: weekdaysView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private enum Constants {
        static let stackViewSpacing: CGFloat = 16
        static let spacingAfterWeekdays: CGFloat = 8
        static let titleColor = UIColor(light: .gray(.shade70), dark: .textSubtle)
    }
}

extension Date {
    var startOfMonth: Date? {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))
    }

    var endOfMonth: Date? {
        guard let startOfMonth = startOfMonth else {
            return nil
        }

        return Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)
    }
}

class WPJTACMonthView: JTACMonthView {

    // Avoids content to scroll above/below the maximum/minimum size
    override func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        let maxY = contentSize.height - frame.size.height
        if contentOffset.y > maxY {
            super.setContentOffset(CGPoint(x: contentOffset.x, y: maxY), animated: animated)
        } else if contentOffset.y < 0 {
            super.setContentOffset(CGPoint(x: contentOffset.x, y: 0), animated: animated)
        } else {
            super.setContentOffset(contentOffset, animated: animated)
        }
    }
}
