import UIKit

class TimeSelectionViewController: UIViewController {

    var preferredWidth: CGFloat = 0

    private lazy var timeSelectionView: TimeSelectionView = {
        let view = TimeSelectionView(selectedTime: "10:00 AM")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func loadView() {
        let mainView = timeSelectionView
        mainView.widthAnchor.constraint(equalToConstant: preferredWidth).isActive = true
        self.view = mainView
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calculatePreferredSize()
    }

    private func calculatePreferredSize() {
        let targetSize = CGSize(width: view.bounds.width,
          height: UIView.layoutFittingCompressedSize.height)
        preferredContentSize = view.systemLayoutSizeFitting(targetSize)
        navigationController?.preferredContentSize = preferredContentSize
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

// MARK: - DrawerPresentable

extension TimeSelectionViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        return .intrinsicHeight
    }
}

extension TimeSelectionViewController: ChildDrawerPositionable {
    var preferredDrawerPosition: DrawerPosition {
        return .collapsed
    }
}


class TimeSelectionView: UIView {

    private var selectedTime: String

    private lazy var timePicker: UIDatePicker = {
        let datePicker = UIDatePicker()

        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }

        datePicker.datePickerMode = .time
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        return datePicker
    }()

    private lazy var timePickerContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timePicker)
        return view
    }()

    private lazy var titleBar: TimeSelectionButton = {
        let button = TimeSelectionButton(selectedTime: selectedTime, insets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
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

    init(selectedTime: String) {
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
}
