import UIKit

class TimeSelectionViewController: UIViewController {

    var preferredWidth: CGFloat = 0

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
        let button = TimeSelectionButton(selectedTime: "3:00 PM", insets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = false
        button.isChevronHidden = true
        return button
    }()

    private lazy var verticalStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleBar, horizontalStackView])
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

    override func loadView() {
        let mainView = UIView()
        mainView.translatesAutoresizingMaskIntoConstraints = false
        mainView.backgroundColor = .basicBackground
        mainView.addSubview(verticalStackView)
        mainView.pinSubviewToSafeArea(verticalStackView)
        NSLayoutConstraint.activate([
            timePicker.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
            mainView.widthAnchor.constraint(equalToConstant: preferredWidth),
            titleBar.widthAnchor.constraint(equalTo: mainView.widthAnchor)
        ])
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
