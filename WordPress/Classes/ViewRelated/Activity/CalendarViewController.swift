import UIKit

protocol CalendarViewControllerDelegate: class {
    func didCancel(calendar: CalendarViewController)
    func didSelect(calendar: CalendarViewController, startDate: Date?, endDate: Date?)
}

class CalendarViewController: UINavigationController {
    init(delegate: CalendarViewControllerDelegate?) {
        let yearCalendarViewController = YearCalendarViewController()
        yearCalendarViewController.delegate = delegate
        super.init(rootViewController: yearCalendarViewController)
    }

    init() {
        super.init(rootViewController: YearCalendarViewController())
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
}

class YearCalendarViewController: UIViewController {

    private var calendarCollectionView: CalendarCollectionView!
    private var startDateLabel: UILabel!
    private var separatorDateLabel: UILabel!
    private var endDateLabel: UILabel!

    private var startDate: Date?
    private var endDate: Date?

    weak var delegate: CalendarViewControllerDelegate?

    private lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d, yyyy")
        return formatter
    }()

    private enum Constants {
        static let headerPadding: CGFloat = 16
    }

    override func viewDidLoad() {
        title = NSLocalizedString("Choose date range", comment: "Title to choose date range in a calendar")

        // Configure Calendar
        let calendar = Calendar.current
        self.calendarCollectionView = CalendarCollectionView(calendar: calendar, style: .year)

        // Configure headers and add the calendar to the view
        let header = startEndDateHeader()
        let stackView = UIStackView(arrangedSubviews: [
                                            header,
                                            WeekdaysHeaderView(calendar: calendar),
                                            calendarCollectionView
        ])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setCustomSpacing(Constants.headerPadding, after: header)
        view.addSubview(stackView)
        view.pinSubviewToAllEdges(stackView, insets: UIEdgeInsets(top: Constants.headerPadding, left: 0, bottom: 0, right: 0))
        view.backgroundColor = .basicBackground

        setupNavButtons()

        calendarCollectionView.calDataSource.didSelect = { [weak self] startDate, endDate in
            self?.updateDates(startDate: startDate, endDate: endDate)
        }

        calendarCollectionView.scrollsToTop = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        scrollToCurrentDate()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        calendarCollectionView.reloadData()
    }

    private func setupNavButtons() {
        let doneButton = UIBarButtonItem(title: NSLocalizedString("Done", comment: "Label for Done button"), style: .done, target: self, action: #selector(done))
        navigationItem.setRightBarButton(doneButton, animated: false)

        navigationItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel)), animated: false)
    }

    private func updateDates(startDate: Date?, endDate: Date?) {
        self.startDate = startDate
        self.endDate = endDate

        updateLabels()
    }

    private func updateLabels() {
        guard let startDate = startDate else {
            resetLabels()
            return
        }

        startDateLabel.text = formatter.string(from: startDate)
        startDateLabel.textColor = .text

        if let endDate = endDate {
            endDateLabel.text = formatter.string(from: endDate)
            endDateLabel.textColor = .text
            separatorDateLabel.textColor = .text
        } else {
            endDateLabel.textColor = .textSubtle
            separatorDateLabel.textColor = .textSubtle
        }
    }

    private func startEndDateHeader() -> UIView {
        let header = UIStackView(frame: .zero)
        header.distribution = .fillProportionally

        let startDate = UILabel()
        startDateLabel = startDate
        startDate.font = .preferredFont(forTextStyle: .body)
        if view.effectiveUserInterfaceLayoutDirection == .leftToRight {
            // swiftlint:disable:next inverse_text_alignment
            startDate.textAlignment = .right
        } else {
            // swiftlint:disable:next natural_text_alignment
            startDate.textAlignment = .left
        }
        header.addArrangedSubview(startDate)

        let separator = UILabel()
        separatorDateLabel = separator
        separator.font = .preferredFont(forTextStyle: .body)
        separator.textAlignment = .center
        header.addArrangedSubview(separator)

        let endDate = UILabel()
        endDateLabel = endDate
        endDate.font = .preferredFont(forTextStyle: .body)
        if view.effectiveUserInterfaceLayoutDirection == .leftToRight {
            // swiftlint:disable:next natural_text_alignment
            endDate.textAlignment = .left
        } else {
            // swiftlint:disable:next inverse_text_alignment
            endDate.textAlignment = .right
        }
        header.addArrangedSubview(endDate)

        resetLabels()

        return header
    }

    private func scrollToCurrentDate() {
        if calendarCollectionView.frame.height == 0 {
            calendarCollectionView.superview?.layoutIfNeeded()
        }

        calendarCollectionView.scrollToDate(Date(),
                                            animateScroll: true,
                                            preferredScrollPosition: .centeredVertically,
                                            extraAddedOffset: -(self.calendarCollectionView.frame.height / 2))
    }

    private func resetLabels() {
        startDateLabel.text = NSLocalizedString("Start Date", comment: "Placeholder for the start date in calendar range selection")
        startDateLabel.textColor = .textSubtle

        separatorDateLabel.text = "-"
        separatorDateLabel.textColor = .textSubtle

        endDateLabel.text = NSLocalizedString("End Date", comment: "Placeholder for the end date in calendar range selection")
        endDateLabel.textColor = .textSubtle
    }

    @objc private func done() {
        guard let calendar = navigationController as? CalendarViewController else {
            return
        }

        delegate?.didSelect(calendar: calendar, startDate: startDate, endDate: endDate)
    }

    @objc private func cancel() {
        guard let calendar = navigationController as? CalendarViewController else {
            return
        }

        delegate?.didCancel(calendar: calendar)
    }
}
