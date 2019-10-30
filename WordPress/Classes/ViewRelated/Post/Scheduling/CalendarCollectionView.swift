import Foundation
import JTAppleCalendar

class CalendarCollectionView: JTACMonthView {

    let calDataSource = CalendarDataSource()

    override init() {
        super.init()

        register(DateCell.self, forCellWithReuseIdentifier: "dateCell")

        backgroundColor = .clear

        scrollDirection = .horizontal
        scrollingMode = .stopAtEachCalendarFrame
        showsHorizontalScrollIndicator = false

        ibCalendarDataSource = calDataSource
        ibCalendarDelegate = calDataSource
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        register(DateCell.self, forCellWithReuseIdentifier: "dateCell")

        scrollDirection = .horizontal
        scrollingMode = .stopAtEachCalendarFrame
        showsHorizontalScrollIndicator = false

        ibCalendarDataSource = calDataSource
        ibCalendarDelegate = calDataSource
    }
}

class CalendarDataSource: JTACMonthViewDataSource {

    var willScroll: ((DateSegmentInfo) -> Void)?
    var didScroll: ((DateSegmentInfo) -> Void)?
    var didSelect: ((Date) -> Void)?

    func configureCalendar(_ calendar: JTACMonthView) -> ConfigurationParameters {
        let startDate = Date(timeIntervalSinceReferenceDate: (-24*60*60)*365*50)
        let endDate = Date(timeIntervalSinceReferenceDate: (24*60*60)*365*50)
        return ConfigurationParameters(startDate: startDate, endDate: endDate)
    }
}

extension CalendarDataSource: JTACMonthViewDelegate {
    func calendar(_ calendar: JTACMonthView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTACDayCell {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "dateCell", for: indexPath) as! DateCell
        configureCell(view: cell, cellState: cellState)
        return cell
    }

    func calendar(_ calendar: JTACMonthView, willDisplay cell: JTACDayCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        configureCell(view: cell, cellState: cellState)
    }

    func calendar(_ calendar: JTACMonthView, willScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        willScroll?(visibleDates)
    }

    func calendar(_ calendar: JTACMonthView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        didScroll?(visibleDates)
    }

    func calendar(_ calendar: JTACMonthView, didSelectDate date: Date, cell: JTACDayCell?, cellState: CellState, indexPath: IndexPath) {
        configureCell(view: cell, cellState: cellState)
        didSelect?(date)
    }

    func calendar(_ calendar: JTACMonthView, didDeselectDate date: Date, cell: JTACDayCell?, cellState: CellState, indexPath: IndexPath) {
        configureCell(view: cell, cellState: cellState)
    }

    private func configureCell(view: JTACDayCell?, cellState: CellState) {
       guard let cell = view as? DateCell else { return }
       cell.dateLabel?.text = cellState.text
       handleCellTextColor(cell: cell, cellState: cellState)
    }

    private func handleCellTextColor(cell: DateCell, cellState: CellState) {
        if cellState.dateBelongsTo == .thisMonth {
          cell.dateLabel?.textColor = .text
        } else {
          cell.dateLabel?.textColor = .textSubtle
        }

        if cellState.isSelected {
            cell.dateLabel?.textColor = .textInverted
        }

        cell.dateLabel?.backgroundColor = cellState.isSelected ? WPStyleGuide.wordPressBlue() : .clear
    }
}

class DateCell: JTACDayCell {

    weak var dateLabel: UILabel?

    override init(frame: CGRect) {
        super.init(frame: frame)

        let dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.textAlignment = .center
        dateLabel.font = UIFont.preferredFont(forTextStyle: .callout)

        // Show circle behind text for selected day
        dateLabel.clipsToBounds = true
        dateLabel.layer.cornerRadius = 28/2

        addSubview(dateLabel)

        NSLayoutConstraint.activate([
            dateLabel.widthAnchor.constraint(equalToConstant: 28),
            dateLabel.heightAnchor.constraint(equalTo: dateLabel.widthAnchor),
            dateLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            dateLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])

        self.dateLabel = dateLabel
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
