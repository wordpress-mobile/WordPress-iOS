// A UIView with a centered "grip" view (like in Apple Maps)
class GripButton: UIButton {

    private enum Constants {
        static let width: CGFloat = 32
        static let height: CGFloat = 5
    }

    convenience init() {
        let gripView = UIView()
        gripView.layer.cornerRadius = Constants.height / 2
        gripView.translatesAutoresizingMaskIntoConstraints = false
        gripView.isUserInteractionEnabled = false
        self.init(frame: .zero)

        addSubview(gripView)

        gripView.backgroundColor = .placeholderElement

        NSLayoutConstraint.activate([
            gripView.widthAnchor.constraint(equalToConstant: Constants.width),
            gripView.heightAnchor.constraint(equalToConstant: Constants.height),
            gripView.centerXAnchor.constraint(equalTo: centerXAnchor),
            gripView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
