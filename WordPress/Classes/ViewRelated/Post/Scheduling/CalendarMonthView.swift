import Foundation
import Gridicons

class CalendarMonthView: UIView {

    private struct Constants {
        static let rowHeight: CGFloat = 44
        static let rowInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        static let calendarHeight: CGFloat = 240
        static let calendarWidth: CGFloat = 375
    }

    weak var headerTitle: UILabel?
    weak var forwardButton: UIButton?
    weak var previousButton: UIButton?

    var updated: ((Date) -> Void)?

    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM, YYYY"
        return formatter
    }()

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
        calendarCollectionView.calDataSource.didScroll = { [weak self] dateSegment in
            if let visibleDate = dateSegment.monthDates.first?.date {
                self?.headerTitle?.text = CalendarMonthView.dateFormatter.string(from: visibleDate)
            }
        }
        calendarCollectionView.calDataSource.didSelect = { [weak self] dateSegment in
            self?.updated?(dateSegment)
        }

        let weekdaysHeaderView = makeWeekdayHeaderView()
        let calendarHeaderView = makeCalendarHeaderView()

        let stackView = UIStackView(arrangedSubviews: [
            calendarHeaderView,
            weekdaysHeaderView,
            calendarCollectionView
        ])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.layoutMargins = Constants.rowInsets
        stackView.isLayoutMarginsRelativeArrangement = true

        setupConstraints(calendarHeaderView: calendarHeaderView, weekdaysHeaderView: weekdaysHeaderView, calendarCollectionView: calendarCollectionView)

        addSubview(stackView)

        pinSubviewToAllEdges(stackView)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        calendarCollectionView.reloadData()
        if let date = selectedDate {
            calendarCollectionView.scrollToDate(date)
        }
    }

    private func setupConstraints(calendarHeaderView: UIView, weekdaysHeaderView: UIView, calendarCollectionView: UIView) {
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
    }

    // MARK: View Factories
    private func makeCalendarHeaderView() -> UIView {
        let prevButton = UIButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        prevButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        prevButton.setImage(Gridicon.iconOfType(.chevronLeft).imageFlippedForRightToLeftLayoutDirection(), for: .normal)
        prevButton.addTarget(self, action: #selector(CalendarMonthView.previousMonth), for: .touchUpInside)

        let nextButton = UIButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        nextButton.setImage(Gridicon.iconOfType(.chevronRight).imageFlippedForRightToLeftLayoutDirection(), for: .normal)
        nextButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nextButton.addTarget(self, action: #selector(CalendarMonthView.nextMonth), for: .touchUpInside)

        let headerLabel = UILabel()
        headerLabel.textAlignment = .center
        headerLabel.textColor = .neutral(.shade60)

        headerTitle = headerLabel

        let headerStackView = UIStackView(arrangedSubviews: [
            prevButton,
            headerLabel,
            nextButton
        ])
        headerStackView.alignment = .center

        return headerStackView
    }

    private func makeWeekdayHeaderView() -> UIView {
        let weekdaysHeader = UIStackView(arrangedSubviews: Calendar.current.veryShortWeekdaySymbols.map({ symbol in
            let label = UILabel()
            label.text = symbol
            label.textAlignment = .center
            label.font = UIFont.preferredFont(forTextStyle: .caption1)
            label.textColor = .neutral(.shade30)
            return label
        }))
        weekdaysHeader.distribution = .fillEqually
        return weekdaysHeader
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
