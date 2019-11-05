import Foundation
import JTAppleCalendar

class CalendarCollectionView: JTACMonthView {

    let calDataSource = CalendarDataSource()

    override init() {
        super.init()

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    private func setup() {
        register(DateCell.self, forCellWithReuseIdentifier: DateCell.Constants.reuseIdentifier)

        backgroundColor = .clear

        scrollDirection = .horizontal
        scrollingMode = .stopAtEachCalendarFrame
        showsHorizontalScrollIndicator = false

        calendarDataSource = calDataSource
        calendarDelegate = calDataSource
    }
}

class CalendarDataSource: JTACMonthViewDataSource {

    var willScroll: ((DateSegmentInfo) -> Void)?
    var didScroll: ((DateSegmentInfo) -> Void)?
    var didSelect: ((Date) -> Void)?

    func configureCalendar(_ calendar: JTACMonthView) -> ConfigurationParameters {
        let startDate = Date.farPastDate
        let endDate = Date.farFutureDate
        return ConfigurationParameters(startDate: startDate, endDate: endDate)
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
        configure(cell: cell, with: cellState)
        didSelect?(date)
    }

    func calendar(_ calendar: JTACMonthView, didDeselectDate date: Date, cell: JTACDayCell?, cellState: CellState, indexPath: IndexPath) {
        configure(cell: cell, with: cellState)
    }

    private func configure(cell: JTACDayCell?, with state: CellState) {
        let cell = cell as? DateCell
        cell?.configure(with: state)
    }

    private func handleCellTextColor(cell: DateCell, cellState: CellState) {

        let textColor: UIColor

        if cellState.isSelected {
          textColor = .textInverted
        } else if cellState.dateBelongsTo == .thisMonth {
          textColor = .text
        } else {
          textColor = .textSubtle
        }

        cell.dateLabel.textColor = textColor

        cell.dateLabel.backgroundColor = cellState.isSelected ? WPStyleGuide.wordPressBlue() : .clear
    }
}

class DateCell: JTACDayCell {

    struct Constants {
        static let labelSize: CGFloat = 28
        static let reuseIdentifier = "dateCell"
    }

    let dateLabel = UILabel()

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
    }
}

extension DateCell {
    func configure(with state: CellState) {

        dateLabel.text = state.text

        let textColor: UIColor

        if state.isSelected {
          textColor = .textInverted
        } else if state.dateBelongsTo == .thisMonth {
          textColor = .text
        } else {
          textColor = .textSubtle
        }

        dateLabel.textColor = textColor

        dateLabel.backgroundColor = state.isSelected ? WPStyleGuide.wordPressBlue() : .clear
    }
}
