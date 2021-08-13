import UIKit

class TimeSelectionButton: UIButton {

    private(set) var selectedTime: String {
        didSet {
            timeLabel.text = selectedTime
        }
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? .divider : .basicBackground
            setNeedsDisplay()
        }
    }

    var isChevronHidden = false {
        didSet {
            chevronStackView.isHidden = isChevronHidden
        }
    }

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isUserInteractionEnabled = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.axis = .horizontal
        return stackView
    }()

    private lazy var pickerTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.text = Self.title
        return label
    }()

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.text = selectedTime
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var chevron: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage.gridicon(.chevronRight)
        imageView.tintColor = .divider
        return imageView
    }()

    private lazy var chevronStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubviews([UIView(), chevron, UIView()])
        return stackView
    }()

    private func configureStackView() {
        stackView.addArrangedSubviews([pickerTitleLabel, UIView(), timeLabel, chevronStackView])
        chevronStackView.isHidden = isChevronHidden
    }

    init(selectedTime: String, insets: UIEdgeInsets = UIEdgeInsets.zero) {
        self.selectedTime = selectedTime
        super.init(frame: .zero)
        configureStackView()
        addSubview(stackView)
        pinSubviewToAllEdges(stackView, insets: insets)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSelectedTime(_ selectedTime: String) {
        self.selectedTime = selectedTime
    }

    static let title = NSLocalizedString("Notification time", comment: "Title for the time picker button in Blogging Reminders.")
}
