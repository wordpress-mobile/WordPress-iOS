import Foundation
import Gridicons

class CalendarMonthView: UIView {

    private struct Constants {
        static let rowHeight: CGFloat = 44
        static let rowInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        static let calendarHeight: CGFloat = 240
        static let calendarWidth: CGFloat = 375
    }

    var updated: ((Date) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        let collectionView = CalendarCollectionView()

        calendarCollectionView = collectionView

        collectionView.calDataSource.didScroll = { [weak self] dateSegment in
            if let visibleDate = dateSegment.monthDates.first?.date {
                self?.headerTitle?.text = CalendarMonthView.dateFormatter.string(from: visibleDate)
            }
        }
        collectionView.calDataSource.didSelect = { [weak self] dateSegment in
            self?.updated?(dateSegment)
        }

        let weekdayHeaders = UIStackView(arrangedSubviews: Calendar.current.veryShortWeekdaySymbols.map({ symbol in
            let label = UILabel()
            label.text = symbol
            label.textAlignment = .center
            label.font = UIFont.preferredFont(forTextStyle: .caption1)
            label.textColor = .neutral(.shade30)
            return label
        }))
        weekdayHeaders.distribution = .fillEqually

        let prevButton = UIButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        prevButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        prevButton.setImage(Gridicon.iconOfType(.chevronLeft).imageFlippedForRightToLeftLayoutDirection(), for: .normal)
        prevButton.addTarget(self, action: #selector(CalendarMonthView.previousMonth), for: .touchUpInside)

        let nextButton = UIButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        nextButton.setImage(Gridicon.iconOfType(.chevronRight).imageFlippedForRightToLeftLayoutDirection(), for: .normal)
        nextButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nextButton.addTarget(self, action: #selector(CalendarMonthView.nextMonth), for: .touchUpInside)

        let headerLabel = UILabel()
        headerLabel.text = "February, 2019"
        headerLabel.textAlignment = .center
        headerLabel.textColor = .neutral(.shade60)

        headerTitle = headerLabel

        let headerStackView = UIStackView(arrangedSubviews: [
            prevButton,
            headerLabel,
            nextButton
        ])
        headerStackView.alignment = .center

        let stackView = UIStackView(arrangedSubviews: [
            headerStackView,
            weekdayHeaders,
            collectionView
        ])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.layoutMargins = Constants.rowInsets
        stackView.isLayoutMarginsRelativeArrangement = true

        let heightConstraint = headerStackView.heightAnchor.constraint(equalToConstant: Constants.rowHeight)
        let widthConstraint = weekdayHeaders.heightAnchor.constraint(equalToConstant: Constants.rowHeight)
        heightConstraint.priority = .defaultHigh
        widthConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            heightConstraint,
            widthConstraint
        ])

        headerStackView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        weekdayHeaders.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        addSubview(stackView)

        let collectionViewSizeConstraints = [
            collectionView.heightAnchor.constraint(equalToConstant: Constants.calendarHeight),
            collectionView.widthAnchor.constraint(equalToConstant: Constants.calendarWidth)
        ]

        collectionViewSizeConstraints.forEach() { constraint in
            constraint.priority = .defaultHigh
        }

        NSLayoutConstraint.activate(collectionViewSizeConstraints)

        pinSubviewToAllEdges(stackView)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        calendarCollectionView?.reloadData()
        if let date = selectedDate {
            calendarCollectionView?.scrollToDate(date)
        }
    }

    var selectedDate: Date? {
        didSet {
            if let date = selectedDate {
                calendarCollectionView?.selectDates([date])
                calendarCollectionView?.scrollToDate(date)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM, YYYY"
        return formatter
    }()

    @IBOutlet weak var headerTitle: UILabel?
    @IBOutlet weak var forwardButton: UIButton?
    @IBOutlet weak var previousButton: UIButton?

    @IBOutlet private weak var calendarCollectionView: CalendarCollectionView?

    @IBAction func previousMonth(_ sender: Any) {
        if let lastVisibleDate = calendarCollectionView?.visibleDates().monthDates.first?.date {
            let nextVisibleDate = lastVisibleDate.addingTimeInterval(-(24 * 60 * 60)) // A far past date
            calendarCollectionView?.scrollToDate(nextVisibleDate)
        }
    }

    @IBAction func nextMonth(_ sender: Any) {
        if let lastVisibleDate = calendarCollectionView?.visibleDates().monthDates.last?.date {
            let nextVisibleDate = lastVisibleDate.addingTimeInterval(24 * 60 * 60) // A far future date
            calendarCollectionView?.scrollToDate(nextVisibleDate)
        }
    }
}
