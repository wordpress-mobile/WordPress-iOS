import Foundation
import Gridicons

class CalendarMonthView: UIView {

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

        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true

        stackView.addConstraints([
            headerStackView.heightAnchor.constraint(equalToConstant: 44),
            weekdayHeaders.heightAnchor.constraint(equalToConstant: 44)
        ])

        addSubview(stackView)
        
        stackView.addConstraints([
            collectionView.heightAnchor.constraint(equalToConstant: 240),
            collectionView.widthAnchor.constraint(equalToConstant: 375)
        ])
        
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
            let nextVisibleDate = lastVisibleDate.addingTimeInterval(-(24 * 60 * 60))
            calendarCollectionView?.scrollToDate(nextVisibleDate)
        }
    }

    @IBAction func nextMonth(_ sender: Any) {
        if let lastVisibleDate = calendarCollectionView?.visibleDates().monthDates.last?.date {
            let nextVisibleDate = lastVisibleDate.addingTimeInterval(24 * 60 * 60)
            calendarCollectionView?.scrollToDate(nextVisibleDate)
        }
    }
}
