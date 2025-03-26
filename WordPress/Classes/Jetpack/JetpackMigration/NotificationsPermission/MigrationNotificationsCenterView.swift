import UIKit

class MigrationNotificationsCenterView: UIView {

    private lazy var explainerImageView: UIImageView = {
        let imageView = UIImageView(image: Appearance.explainerImage(for: traitCollection.layoutDirection))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return imageView
    }()

    init() {
        super.init(frame: .zero)
        addSubview(explainerImageView)
        pinSubviewToAllEdges(explainerImageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard traitCollection.layoutDirection != previousTraitCollection?.layoutDirection else {
            return
        }
        // probably an edge case, but if users change language direction, then update the fake alert
        explainerImageView.image = Appearance.explainerImage(for: traitCollection.layoutDirection)
    }

    private enum Appearance {

        static func explainerImage(for textDirection: UITraitEnvironmentLayoutDirection) -> UIImage? {
            let imageName = textDirection == .rightToLeft ? "wp-migration-notifications-explainer-rtl" : "wp-migration-notifications-explainer-ltr"
            return UIImage(named: imageName)
        }
    }
}
