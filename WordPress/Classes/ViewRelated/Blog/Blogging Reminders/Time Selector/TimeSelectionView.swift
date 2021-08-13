import UIKit

/// A view that contains a time picker and a title reporting the selected time
class TimeSelectionView: UIView {

    private var selectedTime: Date

    private lazy var timePicker: UIDatePicker = {
        let datePicker = UIDatePicker()

        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }

        datePicker.datePickerMode = .time
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.setDate(selectedTime, animated: false)
        return datePicker
    }()

    private lazy var timePickerContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timePicker)
        return view
    }()

    private lazy var titleBar: TimeSelectionButton = {
        let button = TimeSelectionButton(selectedTime: selectedTime.toTime(), insets: Self.titleInsets)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = false
        button.isChevronHidden = true
        return button
    }()

    private lazy var verticalStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleBar, horizontalStackView, bottomSpacer])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        return stackView
    }()

    private func makeSpacer() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    private lazy var leftSpacer: UIView = {
        makeSpacer()
    }()

    private lazy var rightSpacer: UIView = {
        makeSpacer()
    }()

    private lazy var horizontalStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [leftSpacer, timePicker, rightSpacer])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        return stackView
    }()

    private lazy var bottomSpacer: UIView = {
        makeSpacer()
    }()

    init(selectedTime: Date) {
        self.selectedTime = selectedTime
        super.init(frame: .zero)

        backgroundColor = .basicBackground
        addSubview(verticalStackView)
        pinSubviewToSafeArea(verticalStackView)
        NSLayoutConstraint.activate([
            timePicker.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleBar.widthAnchor.constraint(equalTo: widthAnchor),
            bottomSpacer.heightAnchor.constraint(equalTo: titleBar.heightAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func getDate() -> Date {
        timePicker.date
    }

    static let titleInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
}

/// Extracts the time from the passed date
private extension Date {
    func toTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
