import UIKit

class BlogDetailsSectionFooterView: UITableViewHeaderFooterView {
    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        titleLabel.font = WPStyleGuide.tableviewSectionFooterFont()
        titleLabel.textColor = .neutral(.shade40)
        return titleLabel
    }()
    private let spacerView = UIView(frame: .zero)

    override public init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    private func setupSubviews() {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, spacerView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            // Stack view.
            stackView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.readableContentGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.readableContentGuide.bottomAnchor),
            // Spacer view.
            spacerView.heightAnchor.constraint(equalToConstant: 20),
            ])
        updateUI(title: nil, shouldShowExtraSpacing: false)
    }

    @objc func updateUI(title: String?, shouldShowExtraSpacing: Bool) {
        titleLabel.text = title
        spacerView.isHidden = !shouldShowExtraSpacing
    }
}
