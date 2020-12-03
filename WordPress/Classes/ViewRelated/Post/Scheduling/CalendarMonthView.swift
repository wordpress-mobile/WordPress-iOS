import Foundation
import Gridicons

/// A view containing a `CalendarHeaderView`, `WeekdaysHeaderView` and `CalendarCollectionView`
class CalendarMonthView: UIView {

    private struct Constants {
        static let rowHeight: CGFloat = 44
        static let rowInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        static let calendarHeight: CGFloat = 240
        static let calendarWidth: CGFloat = 375
    }

    var updated: ((Date) -> Void)?

    var selectedDate: Date? {
        didSet {
            if let date = selectedDate {
                calendarCollectionView.selectDates([date])
                calendarCollectionView.scrollToDate(date, animateScroll: false)
            }
        }
    }

    private let calendar: Calendar
    private let calendarCollectionView: CalendarCollectionView

    init(calendar: Calendar) {
        self.calendar = calendar
        self.calendarCollectionView = CalendarCollectionView(calendar: calendar)
        super.init(frame: .zero)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        let weekdaysHeaderView = WeekdaysHeaderView(calendar: calendar)
        let calendarHeaderView = CalendarHeaderView(calendar: calendar, next: (self, #selector(CalendarMonthView.nextMonth)), previous: (self, #selector(CalendarMonthView.previousMonth)))

        let stackView = UIStackView(arrangedSubviews: [
            calendarHeaderView,
            weekdaysHeaderView,
            calendarCollectionView
        ])
        stackView.axis = .vertical
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = Constants.rowInsets

        setupConstraints(calendarHeaderView: calendarHeaderView, weekdaysHeaderView: weekdaysHeaderView, calendarCollectionView: calendarCollectionView, stackView: stackView)

        addSubview(stackView)

        pinSubviewToAllEdges(stackView)

        calendarCollectionView.calDataSource.didScroll = { [weak calendarHeaderView] dateSegment in
            if let visibleDate = dateSegment.monthDates.first?.date {
                calendarHeaderView?.set(date: visibleDate)
            }
        }
        calendarCollectionView.calDataSource.didSelect = { [weak self] dateSegment, _ in
            guard let dateSegment = dateSegment else {
                return
            }

            self?.updated?(dateSegment)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        calendarCollectionView.reloadData()
        if let date = selectedDate {
            calendarCollectionView.scrollToDate(date)
        }
    }

    private func setupConstraints(calendarHeaderView: UIView, weekdaysHeaderView: UIView, calendarCollectionView: UIView, stackView: UIView) {

        let heightConstraint = calendarHeaderView.heightAnchor.constraint(equalToConstant: Constants.rowHeight)
        let widthConstraint = weekdaysHeaderView.heightAnchor.constraint(equalToConstant: Constants.rowHeight)
        heightConstraint.priority = .defaultHigh
        widthConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            heightConstraint,
            widthConstraint
        ])

        calendarHeaderView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        weekdaysHeaderView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        let collectionViewSizeConstraints = [
            calendarCollectionView.heightAnchor.constraint(equalToConstant: Constants.calendarHeight),
            calendarCollectionView.widthAnchor.constraint(equalToConstant: Constants.calendarWidth)
        ]

        collectionViewSizeConstraints.forEach() { constraint in
            constraint.priority = .defaultHigh
        }

        NSLayoutConstraint.activate(collectionViewSizeConstraints)

        stackView.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: Navigation button selectors
    @objc func previousMonth(_ sender: Any) {
        if let lastVisibleDate = calendarCollectionView.visibleDates().monthDates.first?.date,
           let nextVisibleDate = calendar.date(byAdding: .day, value: -1, to: lastVisibleDate, wrappingComponents: false) {
            calendarCollectionView.scrollToDate(nextVisibleDate)
        }
    }

    @objc func nextMonth(_ sender: Any) {
        if let lastVisibleDate = calendarCollectionView.visibleDates().monthDates.last?.date,
           let nextVisibleDate = calendar.date(byAdding: .day, value: 1, to: lastVisibleDate, wrappingComponents: false) {
            calendarCollectionView.scrollToDate(nextVisibleDate)
        }
    }
}

/// A view containing two buttons to navigate forward and backward and a
class CalendarHeaderView: UIStackView {

    private enum Constants {
        static let buttonSize = CGSize(width: 24, height: 24)
        static let titeLabelColor: UIColor = .neutral(.shade60)
        static let dateFormat = "MMMM, YYYY"
    }

    typealias TargetSelector = (target: Any?, selector: Selector)

    /// A function to set the string of the title label to a given date
    /// - Parameter date: The date to set the `titleLabel`'s text to
    func set(date: Date) {
        titleLabel.text = dateFormatter?.string(from: date)
    }

    let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = Constants.titeLabelColor
        return label
    }()

    private var dateFormatter: DateFormatter? = nil

    convenience init(calendar: Calendar, next: TargetSelector, previous: TargetSelector) {
        let previousButton = UIButton(frame: CGRect(origin: .zero, size: Constants.buttonSize))
        previousButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        previousButton.setImage(UIImage.gridicon(.chevronLeft).imageFlippedForRightToLeftLayoutDirection(), for: .normal)

        let forwardButton = UIButton(frame: CGRect(origin: .zero, size: Constants.buttonSize))
        forwardButton.setImage(UIImage.gridicon(.chevronRight).imageFlippedForRightToLeftLayoutDirection(), for: .normal)

        forwardButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        self.init()

        addArrangedSubviews([
            previousButton,
            titleLabel,
            forwardButton
        ])

        let formatter = DateFormatter()
        formatter.dateFormat = Constants.dateFormat
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone

        dateFormatter = formatter

        alignment = .center

        previousButton.addTarget(previous.target, action: previous.selector, for: .touchUpInside)
        forwardButton.addTarget(next.target, action: next.selector, for: .touchUpInside)
    }
}

/// A view containing weekday symbols horizontally aligned for use in a calendar header
class WeekdaysHeaderView: UIStackView {
    convenience init(calendar: Calendar) {
        /// Adjust the weekday symbols array so that the first week day matches
        let weekdaySymbols = calendar.veryShortWeekdaySymbols.rotateLeft(calendar.firstWeekday - 1)
        self.init(arrangedSubviews: weekdaySymbols.map({ symbol in
            let label = UILabel()
            label.text = symbol
            label.textAlignment = .center
            label.font = UIFont.preferredFont(forTextStyle: .caption1)
            label.textColor = .neutral(.shade30)
            return label
        }))
        self.distribution = .fillEqually
    }
}

extension Collection {
    /// Rotates the array to the left ([1,2,3,4] -> [2,3,4,1])
    /// - Parameter offset: The offset by which to shift the array.
    func rotateLeft(_ offset: Int) -> [Self.Element] {
        let initialDigits = (abs(offset) % self.count)
        let elementToPutAtEnd = Array(self[startIndex..<index(startIndex, offsetBy: initialDigits)])
        let elementsToPutAtBeginning = Array(self[index(startIndex, offsetBy: initialDigits)..<endIndex])
        return elementsToPutAtBeginning + elementToPutAtEnd
    }
}
