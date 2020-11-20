import UIKit

protocol CalendarViewControllerDelegate: class {
    func didCancel(calendar: CalendarViewController)
    func didSelect(calendar: CalendarViewController, startDate: Date, endDate: Date)
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
}

class YearCalendarViewController: UIViewController {

    private var calendarCollectionView: CalendarCollectionView!
    private var startDateLabel: UILabel!
    private var separatorDateLabel: UILabel!
    private var endDateLabel: UILabel!

    private var startDate: Date?
    private var endDate: Date?

    weak var delegate: CalendarViewControllerDelegate?

    private enum Constants {
        static let headerPadding: CGFloat = 16
    }

    override func viewDidLoad() {
        title = NSLocalizedString("Choose date range", comment: "Title to choose date range in a calendar")

        // Configure Calendar
        let calendar = Calendar.current
        self.calendarCollectionView = CalendarCollectionView(calendar: calendar, style: .year)
        scrollToCurrentDate()

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

        calendarCollectionView.calDataSource.didDeselectAllDates = { [weak self] in
            self?.updateDates(startDate: nil, endDate: nil)
        }

        calendarCollectionView.scrollsToTop = false
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        calendarCollectionView.reloadData()
        scrollToCurrentDate()
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

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
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
        startDate.textAlignment = .right
        header.addArrangedSubview(startDate)

        let separator = UILabel()
        separatorDateLabel = separator
        separator.font = .preferredFont(forTextStyle: .body)
        separator.textAlignment = .center
        header.addArrangedSubview(separator)

        let endDate = UILabel()
        endDateLabel = endDate
        endDate.font = .preferredFont(forTextStyle: .body)
        endDate.textAlignment = .left
        header.addArrangedSubview(endDate)

        resetLabels()

        return header
    }

    private func scrollToCurrentDate() {
        calendarCollectionView.scrollToDate(Date(),
                                            animateScroll: false,
                                            preferredScrollPosition: .centeredVertically) { [weak self] in
            guard let self = self else {
                return
            }

            // Manually center the current date vertically (centeredVertically is not working)
            self.calendarCollectionView.setContentOffset(CGPoint(x: 0, y: self.calendarCollectionView.contentOffset.y - self.calendarCollectionView.frame.height / 2), animated: false)
        }
    }

    private func resetLabels() {
        startDateLabel.text = "Start Date"
        startDateLabel.textColor = .textSubtle

        separatorDateLabel.text = "-"
        separatorDateLabel.textColor = .textSubtle

        endDateLabel.text = "End Date"
        endDateLabel.textColor = .textSubtle
    }

    @objc private func done() {
        guard let startDate = startDate, let endDate = endDate,
              let calendar = navigationController as? CalendarViewController else {
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
