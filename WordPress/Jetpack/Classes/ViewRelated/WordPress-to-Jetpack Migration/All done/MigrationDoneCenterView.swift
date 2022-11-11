import UIKit

class MigrationDoneCenterView: UIView {

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(image: Appearance.iconImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return imageView
    }()

    private lazy var spacer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [spacer, iconImageView])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    init() {
        super.init(frame: .zero)
        addSubview(mainStackView)
        pinSubviewToAllEdges(mainStackView)
        NSLayoutConstraint.activate([
            spacer.heightAnchor.constraint(equalTo: iconImageView.heightAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private enum Appearance {
        static let iconImage = UIImage(named: "wp-migration-icon-with-badge")
    }
}
