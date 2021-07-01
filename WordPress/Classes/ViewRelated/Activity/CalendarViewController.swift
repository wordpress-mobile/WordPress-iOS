import UIKit

protocol CalendarViewControllerDelegate: AnyObject {
    func didCancel(calendar: CalendarViewController)
    func didSelect(calendar: CalendarViewController, startDate: Date?, endDate: Date?)
}

class CalendarViewController: UIViewController {

    private var calendarCollectionView: CalendarCollectionView!
    private var startDateLabel: UILabel!
    private var separatorDateLabel: UILabel!
    private var endDateLabel: UILabel!
    private let gradient = GradientView()

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
        static let endDateLabel = NSLocalizedString("End Date", comment: "Placeholder for the end date in calendar range selection")
    }

    /// Creates a full screen year calendar controller
    ///
    /// - Parameters:
    ///   - startDate: An optional Date representing the first selected date
    ///   - endDate: An optional Date representing the end selected date
    init(startDate: Date? = nil, endDate: Date? = nil) {
        self.startDate = startDate
        self.endDate = endDate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        title = NSLocalizedString("Choose date range", comment: "Title to choose date range in a calendar")

        // Configure Calendar
        let calendar = Calendar.current
        self.calendarCollectionView = CalendarCollectionView(
            calendar: calendar,
            style: .year,
            startDate: startDate,
            endDate: endDate
        )

        // Configure headers and add the calendar to the view
        let header = startEndDateHeader()
        let stackView = UIStackView(arrangedSubviews: [
                                            header,
                                            calendarCollectionView
        ])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setCustomSpacing(Constants.headerPadding, after: header)
        view.addSubview(stackView)
        view.pinSubviewToAllEdges(stackView, insets: UIEdgeInsets(top: Constants.headerPadding, left: 0, bottom: 0, right: 0))
        view.backgroundColor = .basicBackground

        setupNavButtons()

        setUpGradient()

        calendarCollectionView.calDataSource.didSelect = { [weak self] startDate, endDate in
            self?.updateDates(startDate: startDate, endDate: endDate)
        }

        calendarCollectionView.scrollsToTop = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        scrollToVisibleDate()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.calendarCollectionView.reloadData(withAnchor: self.startDate ?? Date(), completionHandler: nil)
        }, completion: nil)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        setUpGradientColors()
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
        startDateLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)

        if let endDate = endDate {
            endDateLabel.text = formatter.string(from: endDate)
            endDateLabel.textColor = .text
            endDateLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
            separatorDateLabel.textColor = .text
            separatorDateLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        } else {
            endDateLabel.text = Constants.endDateLabel
            endDateLabel.font = WPStyleGuide.fontForTextStyle(.title3)
            endDateLabel.textColor = .textSubtle
            separatorDateLabel.textColor = .textSubtle
        }
    }

    private func startEndDateHeader() -> UIView {
        let header = UIStackView(frame: .zero)
        header.distribution = .fill

        let startDate = UILabel()
        startDateLabel = startDate
        startDate.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        if view.effectiveUserInterfaceLayoutDirection == .leftToRight {
            // swiftlint:disable:next inverse_text_alignment
            startDate.textAlignment = .right
        } else {
            // swiftlint:disable:next natural_text_alignment
            startDate.textAlignment = .left
        }
        header.addArrangedSubview(startDate)
        startDate.widthAnchor.constraint(equalTo: header.widthAnchor, multiplier: 0.47).isActive = true

        let separator = UILabel()
        separatorDateLabel = separator
        separator.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        separator.textAlignment = .center
        header.addArrangedSubview(separator)
        separator.widthAnchor.constraint(equalTo: header.widthAnchor, multiplier: 0.06).isActive = true

        let endDate = UILabel()
        endDateLabel = endDate
        endDate.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        if view.effectiveUserInterfaceLayoutDirection == .leftToRight {
            // swiftlint:disable:next natural_text_alignment
            endDate.textAlignment = .left
        } else {
            // swiftlint:disable:next inverse_text_alignment
            endDate.textAlignment = .right
        }
        header.addArrangedSubview(endDate)
        endDate.widthAnchor.constraint(equalTo: header.widthAnchor, multiplier: 0.47).isActive = true

        resetLabels()

        return header
    }

    private func scrollToVisibleDate() {
        if calendarCollectionView.frame.height == 0 {
            calendarCollectionView.superview?.layoutIfNeeded()
        }

        if let startDate = startDate {
            calendarCollectionView.scrollToDate(startDate,
                                                animateScroll: true,
                                                preferredScrollPosition: .centeredVertically,
                                                extraAddedOffset: -(self.calendarCollectionView.frame.height / 2))
        } else {
            calendarCollectionView.setContentOffset(CGPoint(
                                                        x: 0,
                                                        y: calendarCollectionView.contentSize.height - calendarCollectionView.frame.size.height
            ), animated: false)
        }

    }

    private func resetLabels() {
        startDateLabel.text = NSLocalizedString("Start Date", comment: "Placeholder for the start date in calendar range selection")

        separatorDateLabel.text = "-"

        endDateLabel.text = Constants.endDateLabel

        [startDateLabel, separatorDateLabel, endDateLabel].forEach { label in
            label?.textColor = .textSubtle
            label?.font = WPStyleGuide.fontForTextStyle(.title3)
        }
    }

    private func setUpGradient() {
        gradient.isUserInteractionEnabled = false
        gradient.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gradient)

        NSLayoutConstraint.activate([
            gradient.heightAnchor.constraint(equalToConstant: 50),
            gradient.topAnchor.constraint(equalTo: calendarCollectionView.topAnchor),
            gradient.leadingAnchor.constraint(equalTo: calendarCollectionView.leadingAnchor),
            gradient.trailingAnchor.constraint(equalTo: calendarCollectionView.trailingAnchor)
        ])

        setUpGradientColors()
    }

    private func setUpGradientColors() {
        gradient.fromColor = .basicBackground
        gradient.toColor = UIColor.basicBackground.withAlphaComponent(0)
    }

    @objc private func done() {
        delegate?.didSelect(calendar: self, startDate: startDate, endDate: endDate)
    }

    @objc private func cancel() {
        delegate?.didCancel(calendar: self)
    }
}
