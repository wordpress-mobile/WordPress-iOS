class SiteIconView: UIView {

    private enum Constants {
        static let imageSize: CGFloat = 64
        static let borderRadius: CGFloat = 4
        static let imageRadius: CGFloat = 2
        static let imagePadding: CGFloat = 4
    }

    private let button: UIButton = {
        let button = UIButton(frame: .zero)
        button.backgroundColor = UIColor.secondaryButtonBackground
        button.clipsToBounds = true
        button.layer.borderColor = UIColor.secondaryButtonBorder.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = Constants.borderRadius
        return button
    }()

    let imageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Constants.imageRadius
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: Constants.imageSize),
            imageView.heightAnchor.constraint(equalToConstant: Constants.imageSize)
        ])
        return imageView
    }()

    let activityIndicator: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .whiteLarge)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        return indicatorView
    }()

    var callback: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        let paddingInsets = UIEdgeInsets(top: Constants.imagePadding, left: Constants.imagePadding, bottom: Constants.imagePadding, right: Constants.imagePadding)

        button.addSubview(imageView)
        button.pinSubviewToAllEdges(imageView, insets: paddingInsets)
        button.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false

        button.addSubview(activityIndicator)
        button.pinSubviewAtCenter(activityIndicator)

        addSubview(button)
        pinSubviewToAllEdges(button)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func tapped() {
        callback?()
    }
}
