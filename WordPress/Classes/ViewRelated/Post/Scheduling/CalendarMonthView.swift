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

    private let calendarCollectionView = CalendarCollectionView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        let weekdaysHeaderView = WeekdaysHeaderView(calendar: Calendar.current)
        let calendarHeaderView = CalendarHeaderView(next: (self, #selector(CalendarMonthView.nextMonth)), previous: (self, #selector(CalendarMonthView.previousMonth)))

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
        calendarCollectionView.calDataSource.didSelect = { [weak self] dateSegment in
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
           let nextVisibleDate = Calendar.current.date(byAdding: .day, value: -1, to: lastVisibleDate, wrappingComponents: false) {
            calendarCollectionView.scrollToDate(nextVisibleDate)
        }
    }

    @objc func nextMonth(_ sender: Any) {
        if let lastVisibleDate = calendarCollectionView.visibleDates().monthDates.last?.date,
           let nextVisibleDate = Calendar.current.date(byAdding: .day, value: 1, to: lastVisibleDate, wrappingComponents: false) {
            calendarCollectionView.scrollToDate(nextVisibleDate)
        }
    }
}

/// A view containing two buttons to navigate forward and backward and a
class CalendarHeaderView: UIStackView {

    typealias TargetSelector = (target: Any?, selector: Selector)

    /// A function to set the string of the title label to a given date
    /// - Parameter date: The date to set the `titleLabel`'s text to
    func set(date: Date) {
        titleLabel.text = CalendarHeaderView.dateFormatter.string(from: date)
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .neutral(.shade60)
        return label
    }()

    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM, YYYY"
        return formatter
    }()

    convenience init(next: TargetSelector, previous: TargetSelector) {
        let previousButton = UIButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        previousButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        previousButton.setImage(Gridicon.iconOfType(.chevronLeft).imageFlippedForRightToLeftLayoutDirection(), for: .normal)

        let forwardButton = UIButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        forwardButton.setImage(Gridicon.iconOfType(.chevronRight).imageFlippedForRightToLeftLayoutDirection(), for: .normal)
        forwardButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        self.init()
        addArrangedSubviews([
            previousButton,
            titleLabel,
            forwardButton
        ])

        alignment = .center

        previousButton.addTarget(previous.target, action: previous.selector, for: .touchUpInside)
        forwardButton.addTarget(next.target, action: next.selector, for: .touchUpInside)
    }
}

/// A view containing weekday symbols horizontally aligned for use in a calendar header
class WeekdaysHeaderView: UIStackView {
    convenience init(calendar: Calendar) {
        self.init(arrangedSubviews: calendar.veryShortWeekdaySymbols.map({ symbol in
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
