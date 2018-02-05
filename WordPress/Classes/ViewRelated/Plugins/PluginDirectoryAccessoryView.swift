import UIKit
import Gridicons

struct PluginDirectoryAccessoryView {

    static let imageSize = CGSize(width: 14, height: 14)

    static func active() -> UIView {
        let icon = Gridicon.iconOfType(.checkmark, withSize: PluginDirectoryAccessoryView.imageSize)
        let color = WPStyleGuide.validGreen()
        let text = NSLocalizedString("Active", comment: "Describes a status of a plugin")

        return PluginDirectoryAccessoryView.label(with: icon, tintColor: color, text: text)
    }

    static func inactive() -> UIView {
        let icon = Gridicon.iconOfType(.cross, withSize: PluginDirectoryAccessoryView.imageSize)
        let color = WPStyleGuide.greyDarken10()
        let text = NSLocalizedString("Inactive", comment: "Describes a status of a plugin")

        return PluginDirectoryAccessoryView.label(with: icon, tintColor: color, text: text)
    }

    static func needsUpdate() -> UIView {
        let icon = Gridicon.iconOfType(.sync, withSize: PluginDirectoryAccessoryView.imageSize)
        let color = WPStyleGuide.warningYellow()
        let text = NSLocalizedString("Needs Update", comment: "Describes a status of a plugin")

        return PluginDirectoryAccessoryView.label(with: icon, tintColor: color, text: text)
    }

    private static func label(with icon: UIImage, tintColor: UIColor, text: String) -> UIView {
        let container = UIView(frame: .zero)
        container.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView(image: icon)
        imageView.tintColor = tintColor

        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = WPStyleGuide.subtitleFont()
        label.textColor = tintColor
        label.text = text

        container.addSubview(imageView)
        container.addSubview(label)

        label.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true

        imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -4).isActive = true

        imageView.centerYAnchor.constraint(equalTo: label.centerYAnchor).isActive = true

        return container
    }

    static func stars(count: Int) -> UIView {
        let totalStars = 5

        let starImageSize = CGSize(width: 12, height: 12)
        let spacing: CGFloat = 0

        let totalWidth = (starImageSize.width * CGFloat(totalStars)) + (spacing * (CGFloat(totalStars) - 1))

        let blueStar = Gridicon.iconOfType(.star, withSize: starImageSize)
        let whiteStar = Gridicon.iconOfType(.starOutline, withSize: starImageSize)
        let color = WPStyleGuide.mediumBlue()

        let container = UIView(frame: .zero)
        container.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = spacing

        container.addSubview(stackView)

        stackView.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        stackView.widthAnchor.constraint(equalToConstant: totalWidth).isActive = true

        for i in 1...totalStars {
            let image: UIImage

            if i <= count {
                image = blueStar
            } else {
                image = whiteStar
            }

            let imageView = UIImageView(image: image)
            imageView.tintColor = color

            stackView.addArrangedSubview(imageView)
        }

        return container
    }


}



