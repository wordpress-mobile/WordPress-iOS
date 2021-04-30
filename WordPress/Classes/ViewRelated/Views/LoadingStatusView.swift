import Foundation

class LoadingStatusView: UIView {
    @objc init(title: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        autoresizingMask = .flexibleWidth
        titleLabel.text = title
        activityIndicator.startAnimating()
        configureLayout()
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .appBarText
        label.font = WPFontManager.systemRegularFont(ofSize: 14.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        label.numberOfLines = 1
        label.textAlignment = .natural
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        addSubview(label)
        return label
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicator.widthAnchor.constraint(equalToConstant: 20.0),
            indicator.heightAnchor.constraint(equalToConstant: 20.0),
            ])
        addSubview(indicator)
        return indicator
    }()

    private func configureLayout() {
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            activityIndicator.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 2.0),
            activityIndicator.trailingAnchor.constraint(equalTo: trailingAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
