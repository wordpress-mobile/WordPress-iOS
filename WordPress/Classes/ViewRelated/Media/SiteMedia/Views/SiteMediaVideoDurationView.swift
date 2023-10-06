import UIKit

final class SiteMediaVideoDurationView: UIView {
    let textLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.33
        layer.shadowRadius = 8

        textLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        textLabel.textColor = UIColor.white

        addSubview(textLabel)
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        // The insets are designed to make the shadow layer look good and don't take
        // too much space in the video.
        NSLayoutConstraint.activate([
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])

        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.shadowPath = CGPath(ellipseIn: bounds.offsetBy(dx: bounds.width / 2, dy: bounds.height / 2), transform: nil)
    }
}
